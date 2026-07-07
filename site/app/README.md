# site/app — shinylive skeleton (X5)

Serverless interactive variant of the dashboard: the Shiny app runs entirely in the
visitor's browser via webR/WASM ([05 §3](../../research/05-shiny-risks-and-alternatives.md)
A2 default; [components/06 §3](../../research/components/06-view-layer-delivery.md) N5 GO).
It renders **precomputed artifacts only** — the archive parquet slices and the tested
`konjecture` SVG builders; no models run in the browser, no server exists (05 RS4 / icebox I2).

| File | Role |
|---|---|
| [app.R](app.R) | The app — thin usage layer over `konjecture` functions (Now / Compare / Scores tabs) |
| [export.R](export.R) | Assembles a self-contained app dir (app + `konjecture/R/site_lib.R` + data) and runs `shinylive::export` → `_dist/` (gitignored, ~72 MB, rebuildable) |
| [smoke.mjs](smoke.mjs) | Headless-Chrome smoke test (plain Node ≥ 21, CDP over the built-in WebSocket): boots `_dist/`, waits for WASM render, clicks through all tabs |

## Build + smoke test

```sh
Rscript site/app/export.R                      # needs shinylive pkg; network on first run (WASM assets)
cd site/app/_dist && python3 -m http.server 8642 &   # any static server; service worker needs http(s)
node site/app/smoke.mjs                        # exit 0 = booted + all tabs interactive
```

**Result 2026-07-07** (N5 residual discharged): boots in ~21 s headless (Chrome, warm service
worker; first visit pays the WASM download, tens of MB — the audited payload constraint),
all three tabs render, Scores shows first-print + settled(8q) rows —
[smoke_screenshot.png](smoke_screenshot.png). Version note: local data.table 1.17.0 vs webR
binary 1.18.4 (export warns; charts/table output verified identical in the smoke run).

## Not yet

Dual-target **US** settled scores (needs ALFRED, owner action O3) — the Scores tab shows
US rows as first-print-only until then, per D4. Deployment (GitHub Pages) is an owner call
once O1 (PR merge) and O5 (license) land.
