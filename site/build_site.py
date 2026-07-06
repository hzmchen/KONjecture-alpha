#!/usr/bin/env python3
"""Generate site/index.html — the N3 Wizard-of-Oz nowcast comparison page.

Static, self-contained (inline SVG + CSS + a little JS), built purely from
data/archive/ + data/raw/manifest.json. No network, no external assets.
Design requirements implemented: self-announcing staleness (research/08 F3),
dual-target disclosure (research/09 D4), per-source declared-target fairness
note (research/09 §4).
"""

import json
from datetime import date, datetime, timezone
from pathlib import Path
from string import Template

import pandas as pd

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "site" / "index.html"

fc = pd.read_parquet(ROOT / "data/archive/forecasts.parquet")
oc = pd.read_parquet(ROOT / "data/archive/outcomes.parquet")
manifest = json.loads((ROOT / "data/raw/manifest.json").read_text())

SOURCES = {  # display order = categorical slot order (validated palette)
    "gdpnow": dict(label="Atlanta Fed GDPNow", cls="s1"),
    "nyfed": dict(label="NY Fed Staff Nowcast", cls="s2"),
    "spf_philly": dict(label="Philly Fed SPF (mean)", cls="s3"),
}

DATA_AS_OF = max(m["retrieved_at"][:10] for m in manifest.values())
BUILT_AT = datetime.now(timezone.utc).strftime("%Y-%m-%d")

us = fc[fc.region == "US"]

# ---- latest quarter with live coverage ----
cover = us.groupby("target_period")["source"].nunique()
q_now = max(tp for tp, n in cover.items() if n >= 2)
evo = {s: us[(us.source == s) & (us.target_period == q_now)]
       .sort_values("forecast_date") for s in SOURCES}
adv_now = oc[(oc.target_period == q_now) & (oc.release_label == "advance")]

# ---- final-before-advance nowcast per completed quarter ----
completed = oc.sort_values("target_period").tail(12)


def final_before(source, tp, pub):
    d = us[(us.source == source) & (us.target_period == tp)
           & (us.forecast_date <= pub)]
    return None if d.empty else d.sort_values("forecast_date").iloc[-1]


rows = []
for _, o in completed.iterrows():
    row = dict(q=o.target_period, advance=o.value_native, pub=o.published_on)
    for s in SOURCES:
        f = final_before(s, o.target_period, o.published_on)
        row[s] = None if f is None else f.value_native
    rows.append(row)

# ---- MAE on the common sample (all three sources present) ----
common = [r for r in rows if all(r[s] is not None for s in SOURCES)]
mae = {s: sum(abs(r[s] - r["advance"]) for r in common) / len(common) for s in SOURCES}
g_all = [(r["q"], r["gdpnow"], r["advance"]) for r in rows if r["gdpnow"] is not None]

# full-history GDPNow MAE straight from the archive
full = []
for _, o in oc.iterrows():
    f = final_before("gdpnow", o.target_period, o.published_on)
    if f is not None:
        full.append(abs(f.value_native - o.value_native))
gdpnow_full_mae = sum(full) / len(full)

# ---- ECB SPF latest round ----
ecb = fc[fc.source == "spf_ecb"]
ecb_last_round = ecb.forecast_date.max()
ecb_latest = ecb[ecb.forecast_date == ecb_last_round].sort_values("target_period")


def esc(x) -> str:
    return str(x).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


# ============ SVG helpers ============

def xscale(dates, x0, x1):
    lo, hi = min(dates), max(dates)
    span = max((hi - lo).days, 1)
    return lambda d: x0 + (d - lo).days / span * (x1 - x0), lo, hi


def yscale(lo, hi, y0, y1):
    return lambda v: y0 + (v - lo) / (hi - lo) * (y1 - y0)


def nice_ticks(lo, hi, n=5):
    import math
    raw = (hi - lo) / n
    step = 10 ** math.floor(math.log10(raw))
    for m in (1, 2, 2.5, 5, 10):
        if step * m >= raw:
            step *= m
            break
    t0 = math.ceil(lo / step) * step
    ticks, t = [], t0
    while t <= hi + 1e-9:
        ticks.append(round(t, 6))
        t += step
    return ticks


def chart_evolution():
    W, H = 860, 330
    ml, mr, mt, mb = 46, 150, 16, 34
    pts = {s: [(r.forecast_date, r.value_native) for r in evo[s].itertuples()]
           for s in SOURCES if len(evo[s])}
    alld = [d for v in pts.values() for d, _ in v]
    allv = [x for v in pts.values() for _, x in v]
    ylo = min(allv) - 0.4
    yhi = max(allv) + 0.4
    fx, dlo, dhi = xscale(alld, ml, W - mr)
    fy = yscale(ylo, yhi, H - mb, mt)

    g = []
    for t in nice_ticks(ylo, yhi):
        y = fy(t)
        g.append(f'<line class="grid" x1="{ml}" y1="{y:.1f}" x2="{W - mr}" y2="{y:.1f}"/>'
                 f'<text class="tick" x="{ml - 8}" y="{y + 4:.1f}" text-anchor="end">{t:g}</text>')
    months = pd.date_range(dlo, dhi, freq="MS")
    for m in months:
        x = fx(m.date())
        g.append(f'<text class="tick" x="{x:.1f}" y="{H - mb + 18}" text-anchor="middle">{m.strftime("%b")}</text>')
    g.append(f'<line class="axis" x1="{ml}" y1="{H - mb}" x2="{W - mr}" y2="{H - mb}"/>')

    hover = []
    for s, meta in SOURCES.items():
        if s not in pts:
            continue
        p = pts[s]
        if len(p) > 1:
            path = "M" + " L".join(f"{fx(d):.1f},{fy(v):.1f}" for d, v in p)
            g.append(f'<path class="line {meta["cls"]}" d="{path}"/>')
        for d, v in p:
            r = 4 if len(p) == 1 else 2.5
            g.append(f'<circle class="dot {meta["cls"]}" cx="{fx(d):.1f}" cy="{fy(v):.1f}" r="{r}"/>')
            hover.append(f'<circle class="hit" cx="{fx(d):.1f}" cy="{fy(v):.1f}" r="11" '
                         f'data-tip="{meta["label"]} · {d} · {v:.2f}% SAAR"/>')
        dl_d, dl_v = p[-1]
        g.append(f'<text class="dl {meta["cls"]}" x="{fx(dl_d) + 8:.1f}" y="{fy(dl_v) + 4:.1f}">'
                 f'{esc(meta["label"].split("(")[0].strip())} {dl_v:.2f}</text>')

    return (f'<svg viewBox="0 0 {W} {H}" role="img" aria-label="Evolution of {q_now} US GDP nowcasts">'
            + "".join(g) + "".join(hover) + "</svg>")


def chart_trackrecord():
    W = 860
    rh = 34
    ml, mr, mt, mb = 84, 30, 26, 30
    H = mt + rh * len(rows) + mb
    vals = [v for r in rows for v in [r["advance"], *[r[s] for s in SOURCES]] if v is not None]
    xlo, xhi = min(vals) - 0.5, max(vals) + 0.5
    fx = yscale(xlo, xhi, ml, W - mr)  # linear map works for x too

    g = []
    for t in nice_ticks(xlo, xhi, 7):
        x = fx(t)
        g.append(f'<line class="grid" x1="{x:.1f}" y1="{mt}" x2="{x:.1f}" y2="{H - mb}"/>'
                 f'<text class="tick" x="{x:.1f}" y="{H - mb + 18}" text-anchor="middle">{t:g}</text>')
    if xlo < 0 < xhi:
        g.append(f'<line class="axis" x1="{fx(0):.1f}" y1="{mt}" x2="{fx(0):.1f}" y2="{H - mb}"/>')

    hover = []
    for i, r in enumerate(reversed(rows)):
        y = mt + i * rh + rh / 2
        g.append(f'<text class="ylab" x="{ml - 10}" y="{y + 4:.1f}" text-anchor="end">{r["q"]}</text>')
        for s, meta in SOURCES.items():
            if r[s] is None:
                continue
            g.append(f'<circle class="dot {meta["cls"]}" cx="{fx(r[s]):.1f}" cy="{y:.1f}" r="5"/>')
            hover.append(f'<circle class="hit" cx="{fx(r[s]):.1f}" cy="{y:.1f}" r="11" '
                         f'data-tip="{meta["label"]} · {r["q"]} · {r[s]:.2f}% (advance {r["advance"]:.2f}%)"/>')
        x = fx(r["advance"])
        g.append(f'<path class="adv" d="M{x:.1f},{y - 7:.1f} l6,7 l-6,7 l-6,-7 z"/>')
        hover.append(f'<circle class="hit" cx="{x:.1f}" cy="{y:.1f}" r="11" '
                     f'data-tip="BEA advance estimate · {r["q"]} · {r["advance"]:.2f}% (published {r["pub"]})"/>')

    return (f'<svg viewBox="0 0 {W} {H}" role="img" aria-label="Final nowcasts vs BEA advance estimate, last {len(rows)} quarters">'
            + "".join(g) + "".join(hover) + "</svg>")


# ============ HTML fragments ============

def tiles():
    t = []
    for s, meta in SOURCES.items():
        if len(evo[s]) == 0:
            continue
        last = evo[s].iloc[-1]
        t.append(f'''<div class="tile"><div class="tile-k"><span class="chip {meta['cls']}"></span>{esc(meta['label'])}</div>
<div class="tile-v">{last.value_native:.2f}<span class="tile-u">% SAAR</span></div>
<div class="tile-m">as of {last.forecast_date}</div></div>''')
    adv_txt = f"{adv_now.iloc[0].value_native:.2f}" if len(adv_now) else "pending"
    adv_m = f"published {adv_now.iloc[0].published_on}" if len(adv_now) else "BEA release expected ~30 days after quarter end"
    t.append(f'''<div class="tile"><div class="tile-k"><span class="chip adv-chip"></span>BEA advance estimate</div>
<div class="tile-v">{adv_txt}</div><div class="tile-m">{adv_m}</div></div>''')
    return "\n".join(t)


def table_view():
    head = "".join(f"<th>{esc(m['label'])}</th>" for m in SOURCES.values())
    body = []
    for r in reversed(rows):
        cells = "".join(f"<td>{'' if r[s] is None else f'{r[s]:.2f}'}</td>" for s in SOURCES)
        body.append(f"<tr><td>{r['q']}</td>{cells}<td><strong>{r['advance']:.2f}</strong></td><td>{r['pub']}</td></tr>")
    maes = "".join(f"<td>{mae[s]:.2f}</td>" for s in SOURCES)
    return f'''<table><thead><tr><th>Quarter</th>{head}<th>BEA advance</th><th>Advance published</th></tr></thead>
<tbody>{"".join(body)}
<tr class="mae"><td>MAE (common sample, n={len(common)})</td>{maes}<td>—</td><td>—</td></tr></tbody></table>'''


def ecb_table():
    r = []
    for _, e in ecb_latest.iterrows():
        r.append(f"<tr><td>{esc(e.target_period)}</td><td>{e.value_native:.2f}</td></tr>")
    return (f'<table class="narrow"><thead><tr><th>Target period</th>'
            f'<th>Mean point forecast (% y-o-y)</th></tr></thead><tbody>{"".join(r)}</tbody></table>')


PAGE = Template(r'''<title>KONjecture — GDP nowcast comparison ($QNOW)</title>
<style>
:root{
  --page:#f9f9f7; --surface:#fcfcfb; --ink:#0b0b0b; --ink2:#52514e; --muted:#898781;
  --grid:#e1e0d9; --axis:#c3c2b7; --border:rgba(11,11,11,.10);
  --c1:#2a78d6; --c2:#1baf7a; --c3:#eda100; --warnbg:#fdf3dc; --warnink:#6b4d00;
}
@media (prefers-color-scheme: dark){:root{
  --page:#0d0d0d; --surface:#1a1a19; --ink:#ffffff; --ink2:#c3c2b7; --muted:#898781;
  --grid:#2c2c2a; --axis:#383835; --border:rgba(255,255,255,.10);
  --c1:#3987e5; --c2:#199e70; --c3:#c98500; --warnbg:#2b230e; --warnink:#e8c377;
}}
:root[data-theme="light"]{
  --page:#f9f9f7; --surface:#fcfcfb; --ink:#0b0b0b; --ink2:#52514e; --muted:#898781;
  --grid:#e1e0d9; --axis:#c3c2b7; --border:rgba(11,11,11,.10);
  --c1:#2a78d6; --c2:#1baf7a; --c3:#eda100; --warnbg:#fdf3dc; --warnink:#6b4d00;
}
:root[data-theme="dark"]{
  --page:#0d0d0d; --surface:#1a1a19; --ink:#ffffff; --ink2:#c3c2b7; --muted:#898781;
  --grid:#2c2c2a; --axis:#383835; --border:rgba(255,255,255,.10);
  --c1:#3987e5; --c2:#199e70; --c3:#c98500; --warnbg:#2b230e; --warnink:#e8c377;
}
body{background:var(--page);color:var(--ink);font:15px/1.55 system-ui,-apple-system,"Segoe UI",sans-serif;margin:0}
main{max-width:940px;margin:0 auto;padding:28px 20px 60px;display:flex;flex-direction:column;gap:22px}
h1{font-size:26px;margin:0;text-wrap:balance}
h2{font-size:17px;margin:0 0 4px}
.sub{color:var(--ink2);margin:2px 0 0}
.eyebrow{font-size:11px;letter-spacing:.09em;text-transform:uppercase;color:var(--muted);margin:0 0 6px}
.banner{background:var(--surface);border:1px solid var(--border);border-radius:8px;padding:10px 14px;color:var(--ink2);font-size:13.5px;display:flex;gap:8px;flex-wrap:wrap}
.banner strong{color:var(--ink)}
#stale{display:none;background:var(--warnbg);color:var(--warnink);border-color:transparent}
.card{background:var(--surface);border:1px solid var(--border);border-radius:10px;padding:16px 18px}
.tiles{display:grid;grid-template-columns:repeat(auto-fit,minmax(190px,1fr));gap:12px}
.tile{background:var(--surface);border:1px solid var(--border);border-radius:10px;padding:12px 14px}
.tile-k{font-size:12.5px;color:var(--ink2);display:flex;align-items:center;gap:7px}
.tile-v{font-size:32px;font-weight:650;margin-top:2px}
.tile-u{font-size:13px;font-weight:400;color:var(--muted);margin-left:4px}
.tile-m{font-size:12px;color:var(--muted)}
.chip{width:10px;height:10px;border-radius:3px;display:inline-block}
.chip.s1{background:var(--c1)} .chip.s2{background:var(--c2)} .chip.s3{background:var(--c3)}
.adv-chip{width:10px;height:10px;display:inline-block;background:var(--ink);transform:rotate(45deg) scale(.8)}
.legend{display:flex;gap:16px;flex-wrap:wrap;font-size:12.5px;color:var(--ink2);margin:6px 0 4px}
.legend span{display:flex;align-items:center;gap:6px}
svg{width:100%;height:auto;display:block}
.grid{stroke:var(--grid);stroke-width:1}
.axis{stroke:var(--axis);stroke-width:1}
.tick,.ylab{fill:var(--muted);font-size:11.5px;font-variant-numeric:tabular-nums}
.ylab{fill:var(--ink2)}
.line{fill:none;stroke-width:2;stroke-linejoin:round}
.line.s1{stroke:var(--c1)} .line.s2{stroke:var(--c2)} .line.s3{stroke:var(--c3)}
.dot.s1{fill:var(--c1)} .dot.s2{fill:var(--c2)} .dot.s3{fill:var(--c3)}
.dot{stroke:var(--surface);stroke-width:2}
.dl{font-size:12px;font-weight:600}
.dl.s1{fill:var(--c1)} .dl.s2{fill:var(--c2)} .dl.s3{fill:var(--c3)}
.adv{fill:var(--ink)}
.hit{fill:transparent;cursor:default}
#tip{position:fixed;pointer-events:none;background:var(--ink);color:var(--page);font-size:12.5px;
     padding:5px 9px;border-radius:6px;opacity:0;transition:opacity .12s;max-width:320px;z-index:9;font-variant-numeric:tabular-nums}
.tablewrap{overflow-x:auto}
table{border-collapse:collapse;width:100%;font-size:13.5px;font-variant-numeric:tabular-nums}
table.narrow{width:auto;min-width:340px}
th{text-align:left;font-size:11.5px;letter-spacing:.05em;text-transform:uppercase;color:var(--muted);font-weight:600}
th,td{padding:6px 12px 6px 0;border-bottom:1px solid var(--grid)}
tr.mae td{color:var(--ink);font-weight:600;border-bottom:none}
.note{font-size:13px;color:var(--ink2)}
.note strong{color:var(--ink)}
footer{font-size:12.5px;color:var(--muted);border-top:1px solid var(--grid);padding-top:14px}
footer a{color:var(--ink2)}
ul{margin:6px 0;padding-left:20px}
@media (prefers-reduced-motion: reduce){#tip{transition:none}}
</style>
<main>
<header>
  <p class="eyebrow">KONjecture-alpha · Wizard-of-Oz prototype</p>
  <h1>US GDP nowcasts, side by side — $QNOW</h1>
  <p class="sub">Official nowcasts and survey forecasts of US real GDP growth, compared against what the
  Bureau of Economic Analysis actually announced first. No model of our own — this page tests whether the
  comparison itself is useful.</p>
</header>

<div class="banner"><span>Data retrieved <strong>$DATA_AS_OF</strong> · page built <strong>$BUILT_AT</strong> ·
static snapshot, updates event-driven, no schedule promised.</span></div>
<div class="banner" id="stale">This snapshot is more than 45 days old. The project is likely dormant
(by design — see the sunset note in the repository); figures below describe the situation as of $DATA_AS_OF.</div>

<section class="tiles">
$TILES
</section>

<section class="card">
  <h2>How the $QNOW nowcasts evolved</h2>
  <p class="sub">Each point is a published forecast of $QNOW annualized q/q growth (% SAAR), plotted on the day it was made.</p>
  <div class="legend">$LEGEND</div>
  $CHART1
</section>

<section class="card">
  <h2>Track record: final nowcast vs first print</h2>
  <p class="sub">For each completed quarter: the last forecast published before BEA's advance estimate (dots)
  against the advance estimate itself (◆). Scored against the <strong>first release</strong> — see target note below.</p>
  <div class="legend">$LEGEND <span><span class="adv-chip"></span>BEA advance</span></div>
  $CHART2
</section>

<section class="card">
  <h2>Table view</h2>
  <div class="tablewrap">$TABLE</div>
  <p class="note">MAE = mean absolute error vs the advance estimate, on the quarters where all three
  sources are available (NY Fed relaunch limits the common sample). GDPNow's full-archive MAE since 2011
  over $GN_N quarters is <strong>$GN_MAE pp</strong>. Philadelphia SPF is a quarterly survey — its "final"
  value is one mid-quarter round, at an information disadvantage vs daily/weekly trackers; the comparison
  is disclosed, not handicapped.</p>
</section>

<section class="card">
  <h2>Euro area — ECB Survey of Professional Forecasters</h2>
  <p class="sub">Latest round ($ECB_ROUND): mean point forecasts of euro-area real GDP growth.</p>
  <div class="tablewrap">$ECBTABLE</div>
  <p class="note">ECB SPF targets <strong>year-on-year</strong> growth for calendar years and rolling quarters —
  not convertible to the q/q measure above, so it is shown separately rather than forced onto the same chart
  (units discipline per the archive schema; euro-area <em>outcome</em> ingestion is a documented next step).</p>
</section>

<section class="card">
  <h2>What "right" means here — the target measure</h2>
  <p class="note">GDP is revised for years, so every score must name its target. This page scores against the
  <strong>first release</strong> (BEA advance) — what GDPNow itself targets and what a reader expects
  ("what will be announced"). A second, <strong>fixed-horizon</strong> score (the value as published k quarters
  later) is the planned scientific default for the leaderboard; it needs later outcome vintages (ALFRED) that
  are not yet ingested, and recent quarters would show it only after k quarters have passed. Producers also
  differ in what they implicitly target — GDPNow declares the advance estimate; others don't declare —
  so rankings on one target can't be read as model quality alone.</p>
</section>

<footer>
  <p>Sources: Atlanta Fed GDPNow spreadsheet · NY Fed Staff Nowcast download · Philadelphia Fed SPF mean
  growth file · ECB SPF microdata. Exact URLs, retrieval timestamps and SHA-256 checksums:
  <code>data/raw/manifest.json</code> in the repository. Published statistics and forecasts are facts;
  this page compiles them for research. Best-effort hobby project — <strong>no SLA, no update schedule</strong>;
  staleness is announced, not hidden.</p>
</footer>
</main>
<div id="tip" role="status"></div>
<script>
(function(){
  var tip = document.getElementById('tip');
  document.querySelectorAll('.hit').forEach(function(h){
    h.addEventListener('mousemove', function(ev){
      tip.textContent = h.getAttribute('data-tip');
      tip.style.left = Math.min(ev.clientX + 14, window.innerWidth - 330) + 'px';
      tip.style.top = (ev.clientY + 14) + 'px';
      tip.style.opacity = 1;
    });
    h.addEventListener('mouseleave', function(){ tip.style.opacity = 0; });
  });
  var built = new Date('$BUILT_AT');
  var days = (Date.now() - built.getTime()) / 864e5;
  if (days > 45) document.getElementById('stale').style.display = 'block';
})();
</script>
''')

legend = "".join(f'<span><span class="chip {m["cls"]}"></span>{esc(m["label"])}</span>'
                 for m in SOURCES.values())

html = PAGE.substitute(
    QNOW=q_now, DATA_AS_OF=DATA_AS_OF, BUILT_AT=BUILT_AT,
    TILES=tiles(), LEGEND=legend, CHART1=chart_evolution(), CHART2=chart_trackrecord(),
    TABLE=table_view(), ECBTABLE=ecb_table(),
    ECB_ROUND=str(ecb_last_round), GN_MAE=f"{gdpnow_full_mae:.2f}", GN_N=str(len(full)),
)
OUT.write_text(html)
print(f"wrote {OUT.relative_to(ROOT)} ({len(html):,} bytes) · quarter={q_now} · common MAE sample n={len(common)}")
