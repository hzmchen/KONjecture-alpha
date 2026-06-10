# Synthesis: Market Gaps, Product–Market Fit, and Recommendations

**Research date:** 2026-06-10 · Builds on [01-supply](01-supply-existing-frameworks.md) and [02-demand](02-demand-users-and-requirements.md); rubrics per [00](00-methodology-and-rubrics.md). Conclusions carry R5 evidence labels.

## 1. The core finding

**The market gap is the *hub*, not the *models*.** [Strong]

- Every individual capability in the Issue #1 vision already exists in mature, open form *somewhere*: estimation libraries (`dfms`, `midasr`, `statsmodels`, `nowcast_lstm`), data access (DBnomics, ALFRED, SPF), evaluation science (`scoringutils`), hub architecture (hubverse/Zoltar), pipeline/compute (`targets`/`crew`), dashboarding (Shiny).
- **No one has assembled them for macroeconomics.** The best vision-coverage score in the R2 scoring belongs to the **hubverse (14/27) — an epidemiology toolchain with zero macro content** — while no macro offering exceeds 10/27. Macro products are strong exactly where the epi toolchain is empty (model production, dashboards) and empty exactly where it is strong (multi-party collection, comparison, vintage-correct evaluation, open extensibility):

| | C1 models | C2 regions | C3 dashboard | C4 collect | C5 review | C6 evaluate | C7 alt-data | C8 backend | C9 open |
|---|---|---|---|---|---|---|---|---|---|
| Best macro offering | 2 | 3 💰 | 2 | 3 💰 | 2 | 2 💰 | 3 | 0 | 2 |
| hubverse/Zoltar | 0 | 0 | 2 | 2 | 2 | 3 | 0 | 2 | 3 |

(💰 = best score held by a paywalled product.) The union covers all nine components; the intersection is nearly empty. KONjecture's opportunity is to be that union: **"a forecast hub for GDP" — hubverse architecture × econometrics libraries × open macro data.** [Strong]

- Where comparison demand exists, it is monetized shallowly (MacroMicro/Trading Economics republishing single official numbers) or expensively (Consensus, FocusEconomics) [Strong]; and the producers themselves decline the role — Atlanta Fed: **[V]** "Our policy is not to comment on or interpret any differences between the forecasts of these two models."

## 2. Rubric R6 — gap opportunity ranking

`Opportunity = Unmet-ness (1–5) × Demand weight (Tier1=3/T2=2/T3=1, from R4) × Feasibility (1–5)`

| Gap (from 01 §10) | Unmet | Demand | Feasibility | **Score** | Reading |
|---|---|---|---|---|---|
| G1 Multi-model, multi-producer comparison platform | 5 | 3 (S2 T1; S3/S5) | 4 (components exist) | **60** | **The MVP** |
| G3 Open institutional-forecast aggregation | 4 | 3 (S2/S3) | 3 (free sources exist; scraping = legal care) | **36** | Seed from open sources (SPF, WEO, AMECO), defer scraping |
| G2 Public vintage-correct evaluation + leaderboard | 5 | 2 (S5/S1/S6) | 3 (scoringutils + ALFRED for US; EU vintages harder) | **30** | The defensible differentiator; phase 2 |
| G4 Cross-country + sub-national open coverage | 4 | 2 (S4) | 2 (sub-national data scarce) | **16** | Phase 3; start countries + EU aggregate only |
| G5 Open cross-country vintage store | 4 | 2 | 2 (large data engineering) | **16** | Build incrementally as a by-product: archive *own* pulls from day 1 |
| G7 Paper → model-variant pipeline | 5 | 1 (speculative) | 1 | **5** | Research moonshot; not roadmap |

G6 (sustainability fragility of academic OSS) is not a product gap but the **top delivery risk** — see §4. [Strong]

## 3. Product–market fit assessment

**Positioning (one sentence):** *The open, neutral place to see, compare, and score real-time GDP forecasts — models and institutions side by side — for anyone who today either pays Consensus/Now-Casting or squints at single-number trackers.*

| Fit dimension | Assessment | Evidence |
|---|---|---|
| Problem–solution fit | **Good.** Requirements R-5/R-6/R-7 (comparison, review, accountability) are documented demand with zero open supply | Strong |
| Differentiation | **Clear** vs. all four competitor classes: producers (single model, no comparison), commercial (paywalled, closed), aggregators (shallow, no evaluation), epi hubs (wrong domain) | Strong |
| Willingness to "pay" (adopt/contribute) | **Plausible, unproven for macro.** Direct precedent in epidemiology (40+ teams, CDC/ECDC adoption); economics has reproducibility tailwinds (World Bank/AEA mandates; BIS: open-sourcing models = "enhanced predictability, accountability, streamlined collaboration" [V]) but no macro forecast hub has been attempted | Moderate |
| Moat (for an OSS project: defensibility of effort) | **The accumulated forecast archive.** Code can be forked; a years-long, vintage-correct archive of point-in-time forecasts cannot be reconstructed later. Start archiving on day 1 | Moderate (by design) |
| Timing | **Favourable.** dfms 1.0 (2026), hubverse maturity (2025 paper), DBnomics institutional adoption, post-COVID nowcasting investment all recent | Moderate |

**Overall: promising product–market fit for an open-source project, conditional on (a) scoping the MVP to the comparison hub (G1+G3-seed), and (b) treating the evaluation archive (G2/G5) as the long-term moat.** [Moderate–Strong]

## 4. Risks and mitigations

| Risk | Severity | Mitigation |
|---|---|---|
| **Maintainer sustainability** — the niche's graveyard: `nowcasting` archived on CRAN "as requires archived package 'matlab'" [V]; OECD Tracker is an unlicensed research repo; euroareanowcast.com a four-person side-project | High | Minimal dependency surface; CI + CRAN discipline; consortium model from early on (hubverse precedent); document everything; DBnomics shows institutional co-funding is attainable (<€200k/yr [V]) |
| **Data licensing/ToS** — Google Trends, paywalled feeds; scraping institutional sites | High | Phase 1 uses only open data (DBnomics, FRED/ALFRED, Eurostat, SPF, WEO, AMECO); alt-data (C7) and scraping later, with per-source legal review |
| **Compute cost** for many models × regions × weekly re-runs | Medium | `targets` caching ("skips costly runtime for tasks that are already up to date" [S]); precompute artifacts, dashboard reads static files; re-estimate parameters monthly, update nowcasts on releases |
| **Shiny scalability** | Medium | Shiny only renders precomputed parquet/pins artifacts; no estimation in the request path |
| **Credibility cold-start** — why trust an unofficial nowcast? | Medium | Don't lead with *our* model being right; lead with *neutral comparison* of official/institutional numbers + fully reproducible backtests; academic partners as co-owners |
| **Vintage data outside US** patchy → vintage-correct evaluation limited initially | Medium | Start US + euro area; archive own ingestions to *create* vintages going forward |
| **Scope creep** — the vision names ~9 product surfaces | High | Phased roadmap below; G7 explicitly out of scope |

## 5. Recommended architecture: combine, don't rebuild

Mapping vision components to the R3 "Adopt" building blocks:

| Vision component | Recommendation |
|---|---|
| C1 Models | Thin **model-adapter interface**; first adapters: `dfms` (DFM/Bańbura–Modugno), `midasr` (MIDAS), AR benchmark; later `nowcast_lstm` via reticulate. Every model must emit **quantile forecasts in hubverse model-output format** |
| C2 Regions | v0: US, euro area, DE, FR, IT, ES, UK via DBnomics/`rdbnomics` + FRED; sub-national deferred |
| C3 Dashboard | Shiny (`golem`), reading only precomputed artifacts; modes: *Now* (current nowcasts + uncertainty), *Compare*, *Review* (expected vs realised) |
| C4 Institutional forecasts | Ingest free sources first: ECB SPF (CSV), Philly Fed SPF, IMF WEO, OECD EO, AMECO, official nowcasts (GDPNow/NY Fed publish their numbers). Scraping = phase 3 |
| C5/C6 Review & evaluation | `scoringutils` (CRPS/WIS, calibration) over the hub-format archive; **append-only forecast + data-vintage archive from the first run** (parquet/DuckDB); leaderboard = phase 2 |
| C7 Alt-data | Phase 3; follow Bundesbank WAI's validated menu (truck toll, electricity, flights) where licensing allows |
| C8 Backend | `targets` + `crew` pipeline; DuckDB/parquet storage; scheduled runs (CI cron) |
| C9 Framework ambition | Satisfied *by construction*: adopting hubverse-compatible formats makes the macro hub a domain instance of a general pattern, not a bespoke architecture |

**Phasing:** v0.1 = one country (euro area or DE), two models + AR benchmark + SPF overlay, Shiny *Now/Compare* view, archive everything. v0.2 = 5–7 regions, *Review* mode. v0.3 = vintage-correct backtest + leaderboard (US first via ALFRED). v1.0 = institutional scraping, sub-national pilots, alt-data.

## 6. What would falsify the fit (validation plan)

1. **Contribution test** — if after ~6 months of public v0.2 no external model/PR/issue engagement from S5 (academics), the "hub" hypothesis weakens → narrow to an *evaluation library + dataset* (the G2/G5 core, which has standalone value).
2. **Usage test** — dashboard analytics + GitHub stars vs. comparable launches (dfms, scoringutils trajectories as baselines).
3. **Institutional test** — one university course, think-tank, or central-bank research unit using the archive in a paper within 12 months (the Zoltar adoption path).
4. **Neutrality test** — first media citation of the *comparison* (not of a single model's number).

## References

Primarily the consolidated reference tables of [01-supply](01-supply-existing-frameworks.md#references) and [02-demand](02-demand-users-and-requirements.md#references); quotes above carry their [V]/[S] tags from those documents.
