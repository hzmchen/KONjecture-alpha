# KONjecture-alpha

Open-source platform (vision stage) for serving, comparing, and evaluating real-time forecasts of economic activity (GDP nowcasts) across regions — nation states, unions such as the EU, and sub-national regions. See [Issue #1 — Product Vision Draft](https://github.com/hzmchen/KONjecture-alpha/issues/1).

## Market research

Extensive market research (2026-06-10) lives in [`research/`](research/):

| Doc | Topic |
|-----|-------|
| [00-methodology-and-rubrics](research/00-methodology-and-rubrics.md) | Method, quote validation, assessment rubrics R1–R6 |
| [01-supply-existing-frameworks](research/01-supply-existing-frameworks.md) | Supply: existing frameworks, coverage, gaps, combinable building blocks |
| [02-demand-users-and-requirements](research/02-demand-users-and-requirements.md) | Demand: user segments, requirements, open-source selling points |
| [03-synthesis-market-gap-and-fit](research/03-synthesis-market-gap-and-fit.md) | Synthesis: market gaps, product–market fit, recommendations |
| [04-summary](research/04-summary.md) | High-level summary |
| [05-shiny-risks-and-alternatives](research/05-shiny-risks-and-alternatives.md) | R Shiny risks; static-first/shinylive recommendation |
| [06-vintage-reconstruction](research/06-vintage-reconstruction.md) | Rebuilding data & forecast vintages from past publications |
| [07-graveyard-negative-cases](research/07-graveyard-negative-cases.md) | Negative cases: how comparable projects died (survivorship-bias sweep) |
| [08-pre-mortem](research/08-pre-mortem.md) | Pre-mortem: ranked failure modes, countermeasures, sunset protocol |
| [09-target-measure-decision](research/09-target-measure-decision.md) | Target-measure decision analysis (Issue #2 / N1): option-4 recommendation, open sub-decisions D1–D4, fairness caveats |
| [components/](research/components/README.md) | Component catalog per architecture layer: capabilities, status, licensing, availability (Issue #3); incl. webR/WASM audit |

Prioritized next steps and the icebox live in [TODO.md](TODO.md). Project premises (one-person Liebhaberei, AI-assisted build) and rubrics: [research/00](research/00-methodology-and-rubrics.md).

## Implementation (started 2026-07-06)

**Pure R** (single runtime by design, ported from the initial Python implementation 2026-07-06 and validated output-identical; `renv.lock` pins the package versions). `targets::tar_make()` in `pipeline/` is the single build entry point: raw cache → archive → models → site.

| Dir | What | Status |
|---|---|---|
| [docs/schema.md](docs/schema.md) | Archive schema v0.1: outcome-as-of-vintage, target rules, hubverse mapping | v0.1 |
| [ingest/](ingest/README.md) | Raw downloads (manifest + SHA256) → normalized `data/archive/` parquet/csv | N4 seeded: 4 sources, 3,285 forecasts, 59 outcomes |
| [data/](data/) | `raw/` upstream cache · `archive/` forecasts, outcomes, model output | append-only |
| [site/](site/build_site.R) | Static Wizard-of-Oz comparison page (self-contained HTML+SVG) + Quarto dashboard (`dashboard.qmd`, X5 fallback; needs the quarto CLI) | N3 built; dashboard v1 |
| [pipeline/](pipeline/README.md) | `targets` graph: archive build + AR(2)/DFM-bridge nowcasts (hubverse-style quantiles) + site build | N2 spike passed; unified |
| [tests/](tests/COVERAGE.md) | `testthat` suite (134 tests, offline, committed cache as fixtures): `Rscript tests/run_tests.R` · coverage: `Rscript tests/coverage.R` | 98.1% line coverage |
| [walkthrough/](walkthrough/README.md) | Linear project walkthrough with verbatim sed-extracted code + screenshots; regenerate via `walkthrough/build.sh` | generated |

Everything runs offline from the committed raw cache; network is touched only by deliberate one-off `Rscript ingest/download_raw.R` runs. Best-effort hobby project: **no SLA, no update schedule** — artifacts announce their own staleness.
