# View Layer & Delivery (C3 dashboard) — incl. the webR/WASM audit (TODO N5)

**Verified 2026-06-10** from CRAN / GitHub releases / repo.r-wasm.org ([method](README.md)). Decision context: [05 §3](../05-shiny-risks-and-alternatives.md) — static-first, shinylive default (A2), Quarto fallback (A3); dashboard only renders precomputed artifacts.

## 1. Core delivery components

| Component | Capabilities | Status [V] | License [V] | Availability | Verdict |
|---|---|---|---|---|---|
| **`shiny`** | The reactive app framework (the hobby premise) | 1.13.0, 2026-02-20 — active, Posit-backed | **MIT** (relicensed from GPL-3) | CRAN; WASM ✓ | **Adopt** |
| **`shinylive`** (R) | Exports a Shiny app to a serverless WASM bundle for static hosting | **0.5.0, 2026-06-08** — released two days before this check | MIT | CRAN | **Adopt as default deployment** (A2) — now confirmed viable by §3 |
| **webR** | R compiled to WebAssembly; runs the exported app in-browser | **v0.6.0, 2026-05-19** [V]; binary repo serves **23,559 packages** for R 4.5 [V] | NOASSERTION on repo (GPL-family; R itself GPL) | repo.r-wasm.org + npm | Underpins shinylive; healthy release cadence |
| `bslib` | Bootstrap theming/layouts for Shiny dashboards | 0.11.0, 2026-05-16 | MIT | CRAN; WASM ✓ | Adopt for dashboard chrome |
| **Quarto** (CLI + R pkg) | Static scientific publishing; dashboards with client-side OJS/plotly | CLI **v1.9.38, 2026-05-25** [V]; R pkg 1.5.1 | MIT | quarto.org / CRAN | **Adopt as A3 fallback** and for the research-notes site |
| GitHub Pages | Static hosting for the exported bundle | platform | free (public) | — | Adopt; Netlify/Cloudflare Pages as drop-in alternates |

## 2. Charting / tables (choose 1–2, keep payload small)

| Component | Capabilities | Status [V] | License [V] | WASM [V] | Verdict |
|---|---|---|---|---|---|
| `ggplot2` | Static grammar-of-graphics (fan charts, score plots) | 4.0.3, 2026-04-22 | MIT | ✓ | Adopt |
| `plotly` | Interactive charts; ggplot2 conversion | 4.12.0, 2026-01-24 | MIT | ✓ | Adopt for interactivity |
| `echarts4r` | Apache ECharts bindings (lighter, pretty time series) | 0.5.0, 2026-02-10 | Apache-2 | ✓ | Alternative to plotly; pick one |
| `reactable` | Interactive tables (leaderboard) | 0.4.5, 2025-12-01 | MIT | ✓ | Adopt for the leaderboard table |
| `DT` | DataTables bindings | 0.34.0, 2025-09-02 | MIT | ✓ | Alternative to reactable; pick one |

## 3. webR/WASM binary audit — **TODO N5 answered: GO for shinylive**

Checked every package the architecture might load **in the browser** (view, read-archive, score, plus the estimation cores as future-proofing) against the webR binary repo (R 4.5 tree, 2026-06-10):

| Available ✓ [V] | Missing ✗ [V] |
|---|---|
| `shiny` `bslib` `ggplot2` `plotly` `echarts4r` `reactable` `DT` `quarto` — view | **`arrow`** — the only miss in 32 checked |
| `nanoparquet` `duckdb` `data.table` `collapse` — archive reading | |
| `scoringutils` `scoringRules` `hubUtils` `hubEnsembles` `zoltr` — scoring/formats | |
| `dfms` `midasr` `midasml` `sparseDFM` `fable` `fabletools` `forecast` `KFAS` — estimation (incl. C++ pkgs) | |
| `rdbnomics` `fredr` `alfred` `eurostat` `ecb` `targets` — misc | |

**Consequences:**
1. The [05 RS5](../05-shiny-risks-and-alternatives.md) risk ("a package with C++ code is usable only if a WASM binary exists — must be checked per package") is **retired**: every needed package has a binary; even `dfms` does.
2. The single gap, `arrow`, dictates the archive read-path split already recommended in [04 §2](04-storage-archive.md): app-side reads use `nanoparquet`/`duckdb`.
3. Remaining shinylive constraints are now only the *structural* ones: payload size (each visitor downloads R + packages — keep the dashboard's package set to the view/read subset, tens of MB), public data only, browser-side compute limits. None binds a dashboard that renders precomputed artifacts.
4. Caveat for the record: binary *presence* ≠ runtime *correctness*; N5's residual is a 1-hour smoke test loading the actual app skeleton in shinylive — fold into N3/X5, no separate research needed.

## 4. Layer assessment

- The hobby premise survives contact with the evidence: a 100%-R, zero-server dashboard is deliverable **today** with the freshest components in the entire catalog (shinylive 0.5.0 two days old, webR 0.6.0 three weeks old) — this corner of the ecosystem is in active institutional development at Posit, not decay.
- Note `shiny` is now MIT-licensed [V] — the view layer is entirely permissive (MIT/Apache), so license constraints concentrate solely in the GPL pipeline side ([README §headline 5](README.md)).

## References

CRAN canonical pages, fetched 2026-06-10 [V]; GitHub releases API: [r-wasm/webr](https://github.com/r-wasm/webr), [quarto-dev/quarto-cli](https://github.com/quarto-dev/quarto-cli) [V]; [repo.r-wasm.org](https://repo.r-wasm.org/) PACKAGES (R 4.5) [V]; [posit-dev/r-shinylive](https://github.com/posit-dev/r-shinylive) [V]; prior analysis: [05-shiny-risks-and-alternatives](../05-shiny-risks-and-alternatives.md).
