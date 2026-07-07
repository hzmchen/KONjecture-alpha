// X5 smoke test driver: boot the shinylive bundle in headless Chrome via CDP,
// wait for the Shiny app (webR/WASM, same-origin iframe) to render, then
// exercise the tabs. Exit 0 = booted and interactive.
import { spawn } from "node:child_process";
import { writeFileSync } from "node:fs";

const URL_APP = "http://127.0.0.1:8642/index.html";
const PORT = 9222;
const chrome = spawn("google-chrome", [
  "--headless=new", "--no-sandbox", "--disable-gpu",
  `--remote-debugging-port=${PORT}`, "--window-size=1200,900", "about:blank",
], { stdio: "ignore" });

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function getWsUrl() {
  for (let i = 0; i < 50; i++) {
    try {
      const res = await fetch(`http://127.0.0.1:${PORT}/json`);
      const page = (await res.json()).find((t) => t.type === "page");
      if (page) return page.webSocketDebuggerUrl;
    } catch {}
    await sleep(200);
  }
  throw new Error("chrome devtools endpoint never came up");
}

const ws = new WebSocket(await getWsUrl());
await new Promise((r) => (ws.onopen = r));
let id = 0;
const pending = new Map();
ws.onmessage = (ev) => {
  const msg = JSON.parse(ev.data);
  if (msg.id && pending.has(msg.id)) { pending.get(msg.id)(msg); pending.delete(msg.id); }
};
const send = (method, params = {}) => new Promise((resolve) => {
  const i = ++id;
  pending.set(i, resolve);
  ws.send(JSON.stringify({ id: i, method, params }));
});
const evaljs = async (expr) =>
  (await send("Runtime.evaluate", { expression: expr, returnByValue: true }))
    .result?.result?.value;

// the app document lives in a same-origin iframe -> reachable from the top frame
const APPDOC = `(document.querySelector('iframe.app-frame')||{}).contentDocument`;

await send("Page.enable");
await send("Runtime.enable");
await send("Page.navigate", { url: URL_APP });

let booted = false, status = "";
const t0 = Date.now();
while (Date.now() - t0 < 240000) {
  await sleep(3000);
  status = await evaljs(`JSON.stringify((d => d ? {
    svg: d.querySelectorAll('svg').length,
    tabs: [...d.querySelectorAll('ul.nav-tabs a')].map(e => e.textContent.trim()),
    text: d.body ? d.body.innerText.slice(0, 160) : ''
  } : { svg: -1, tabs: [], text: 'no iframe doc yet' })(${APPDOC}))`);
  const s = status ? JSON.parse(status) : {};
  process.stderr.write(`t=${Math.round((Date.now() - t0) / 1000)}s svg=${s.svg} tabs=[${(s.tabs || []).join(",")}]\n`);
  if (s.svg > 0 && (s.tabs || []).includes("Scores")) { booted = true; break; }
}

let interaction = null;
if (booted) {
  const click = (label) => evaljs(
    `[...${APPDOC}.querySelectorAll('ul.nav-tabs a')].find(e => e.textContent.trim() === '${label}').click()`);
  await click("Compare");
  await sleep(2000);
  const svgCompare = await evaljs(`${APPDOC}.querySelectorAll('.tab-pane.active svg').length`);
  await click("Scores");
  await sleep(2000);
  const scoreRows = await evaljs(`${APPDOC}.querySelectorAll('.tab-pane.active table tr').length`);
  const settled = await evaljs(`${APPDOC}.querySelector('.tab-pane.active').innerText.includes('settled (8q)')`);
  interaction = { svgCompare, scoreRows, settled };
}

const shot = await send("Page.captureScreenshot");
if (shot.result?.data)
  writeFileSync(new globalThis.URL("./app_screenshot.png", import.meta.url), Buffer.from(shot.result.data, "base64"));

console.log(JSON.stringify({ booted, seconds: Math.round((Date.now() - t0) / 1000), last: JSON.parse(status || "{}"), interaction }, null, 2));
chrome.kill();
process.exit(booted && interaction && interaction.svgCompare > 0 && interaction.settled ? 0 : 1);
