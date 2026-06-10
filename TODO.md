# TODO / Next Steps

Prioritized under the v2 lens ([00 — premises P-A/P-B, rubric R7](research/00-methodology-and-rubrics.md)): items must pass founder-fit gates (dormancy tolerance, energy return, affordable loss) before opportunity scores matter. Out-of-scope and currently intractable items are kept honestly in the **Icebox** with explicit revisit triggers instead of being silently dropped.

## Now (first concrete steps)

| # | Item | Why now | Notes |
|---|------|---------|-------|
| N1 | **Decide the evaluation target measure** — first publication vs final/latest vintage | blocks archive schema design | → [Issue #2](https://github.com/hzmchen/KONjecture-alpha/issues/2); input in [06 §2](research/06-vintage-reconstruction.md) |
| N2 | **Riskiest-assumption spike (1 week):** `targets` pipeline skeleton → DBnomics/FRED pull for one region → AR benchmark + `dfms` model → quantile output in hubverse-style format → append-only parquet archive | tests the *technical* riskiest assumption (solo data plumbing), which the market research could not | success = one reproducible end-to-end run |
| N3 | **Wizard-of-Oz comparison page:** static page comparing *existing* official nowcasts (GDPNow, NY Fed, euro area) — no own model | tests the core J2 value hypothesis in days; zero standing infra | data per [06 §3.1](research/06-vintage-reconstruction.md) |
| N4 | **Seed the archive retroactively:** GDPNow spreadsheet + ALFRED vintages, NY Fed xlsx, ECB/Philly SPF CSVs | removes cold start; the cheapest most differentiating win | [06 §3](research/06-vintage-reconstruction.md) |
| N5 | **webR/WASM package audit** for the intended view-layer stack | decides shinylive default ([05 §3](research/05-shiny-risks-and-alternatives.md)) cheaply, before habits form | check binary availability (e.g. C++-based pkgs) |

## Next (after the spike proves out)

| # | Item | Trigger |
|---|------|---------|
| X1 | Review mode (expected vs realised) over the seeded archive | N4 done |
| X2 | `scoringutils`-based scoring + first vintage-correct backtest (US first, then DE/EA via Gerda/ECB RTD) | N1 decided, N4 done |
| X3 | Add 2nd/3rd model class (`midasr`; `nowcast_lstm` via reticulate) behind a thin model-adapter interface | N2 architecture stable |
| X4 | Expand regions: US, EA, DE, FR, IT, ES, UK | ingestion adapters generalized |
| X5 | Shinylive (or Quarto fallback) dashboard with Now/Compare modes. **Design requirement from [08 F3](research/08-pre-mortem.md): self-announcing staleness** (last-updated banner; automatic dormant-mode notice when artifacts age out) | N3 validated the view; N5 audited |
| X6 | **Methodology debt:** sensitivity check of rubric scores (±1 perturbation). ~~Negative-case sweep + pre-mortem~~ **done** → [07](research/07-graveyard-negative-cases.md), [08](research/08-pre-mortem.md) | before any public "launch" framing |
| X7 | Optional: 3–5 primary conversations (ESCoE, hubverse community, r/econometrics) | when external feedback would be fun, not before |
| X8 | IMF WEO + OECD EO vintage ingestion (global annual institutional tracks) | X1 shipped |
| X9 | **Pre-mortem countermeasures** ([08 §4](research/08-pre-mortem.md)): fail-loud CI; per-source dependency register with fallbacks; per-source license registry; no-SLA note in README; no-streak rule (event-driven cadence, no calendar promises); Zenodo/DOI escrow snapshots of code+archive per release; SUNSET note skeleton | with first public artifact (N3/X5) |

## Later (valuable, not yet)

| # | Item | Why not now |
|---|------|------------|
| L1 | Public leaderboard with uncertainty-aware scores (WIS/CRPS) | needs X2 maturity + fairness rules (target measure, information sets) |
| L2 | Central-bank projection PDFs → forecasts (AI-assisted parsing, one-off per institution) | high effort per source; validation attention is the bottleneck |
| L3 | API / data export for third parties | creates expectations (obligation audit) — only with clear boundaries ("static files, no SLA") |
| L4 | German-language supply sweep (ifo, IfW, DIW, KOF nowcasts) to close the v1 language gap | cheap but not blocking; fold into X4 |

## Icebox (out of scope or intractable now — with revisit triggers)

| # | Item | Why iceboxed | Revisit when |
|---|------|--------------|--------------|
| I1 | **Paper→model pipeline** ("fetch recent research articles and turn them into forecasting machines", Issue #1) | speculative, R6 score 5/75; enormous validation burden | a concrete paper is hand-ported first (do it manually twice, then judge automation) |
| I2 | **Interactive user-triggered re-runs of forecasts/evaluations** | worst R7 offender: compute in request path, standing infra ([05 RS4](research/05-shiny-risks-and-alternatives.md)) | precomputed scenario grids prove insufficient *and* a server is accepted consciously |
| I3 | **Institutional web scraping at scale** | code is cheap (P-B) but babysitting + legal review are attention sinks | a wanted source has no downloadable archive *and* stable markup |
| I4 | **Alt-data ingestion** (Google Trends, mobility, freight, news) | ToS/licensing review per source; pipelines rot fast (dormancy fail) | one specific alt-data source materially improves a tracked model's backtest |
| I5 | **Sub-national coverage beyond available official series** | data scarcity; research-grade methods (NUTS2 MF-DFM) not yet productizable solo | ESCoE-style official regional series become API-accessible for a target country |
| I6 | **Domain-agnostic forecast-evaluation framework** (vision's end state) | premature abstraction; satisfied "by construction" via hubverse-compatible formats | a second domain (e.g. epi course project) actually tries to reuse the stack |
| I7 | **Consortium/governance structures** | one person; governance is overhead without a community | ≥2 sustained external contributors exist |
| I8 | **Wayback-Machine reconstruction** of unarchived forecast pages | high variance, low yield | a specific high-value gap in the seeded archive justifies it |
| I9 | **User-selectable databases for forecast production** | multiplies cache/compute surface | core single-database flow is boring-stable |

## Standing audits (quarterly, from [03 §6](research/03-synthesis-market-gap-and-fit.md))

- **Fun audit** — which parts energized/drained? Redesign or icebox the drains.
- **Obligation audit** — any standing duties to strangers? Automate to indifference or retire.
- **Affordable-loss audit** — time & compute spend within budget.
