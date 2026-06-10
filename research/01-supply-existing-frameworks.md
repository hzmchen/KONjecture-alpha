# Supply: Existing Frameworks, Coverage, Gaps, and Combinable Building Blocks

**Research date:** 2026-06-10 · Quotes tagged **[V]** (verbatim, fetched directly) or **[S]** (via search-result content) per [00-methodology-and-rubrics.md](00-methodology-and-rubrics.md). Source grades A–D per Rubric R1.

## 1. Landscape overview

The supply side splits into six categories. **No single offering — public, commercial, or open-source — covers the KONjecture vision**; but almost every *component* of the vision exists somewhere in mature form.

| Category | Representatives |
|----------|----------------|
| A. Public single-producer nowcasts | Atlanta Fed GDPNow, NY Fed Staff Nowcast, OECD Weekly Tracker, Bundesbank WAI, UNCTAD Nowcasts, euroareanowcast.com, ESCoE (UK regions) |
| B. Commercial services | Now-Casting Economics, Consensus Economics, FocusEconomics, Moody's Analytics; chart aggregators (MacroMicro, Trading Economics) |
| C. Open-source model libraries | R: `dfms`, `midasr`, `nowcasting` (archived); Python: `statsmodels` DynamicFactorMQ, `nowcast_lstm` |
| D. Forecast-hub & evaluation infrastructure | hubverse, Zoltar, `scoringutils` |
| E. Data infrastructure | DBnomics, ALFRED, Philadelphia Fed Real-Time Data Set, ECB SPF data |
| F. App & pipeline infrastructure | R Shiny, `targets` + `crew` |

## 2. Category A — Public single-producer nowcasts

### 2.1 Atlanta Fed GDPNow (USA) — grade B (official explainer, fetched raw)

> **[V]** "GDPNow is a nowcasting model for measuring gross domestic product from the Atlanta Fed. The data tool produces a running estimate of US real GDP growth for the quarter right after the most recent one with an official government estimate, updating whenever new economic data is released."
> **[V]** "The tool should not be interpreted as an official forecast from the Atlanta Fed."
> **[V]** "GDPNow fills an important economic information gap. Users can access a real-time and empirically driven forecast of US GDP growth before official estimates are released."

It self-describes as differentiated by exactly the qualities KONjecture targets: **[V]** "…a 'nowcast' model, one improved from some other GDP nowcasts because of its timeliness, level of detail, and public availability." Methodology (bridge equations + factor model + BVAR over 13 GDP subcomponents) is published, with raw data in Excel — but the code is closed. A practitioner write-up (grade D, colour only) puts it sharply:

> **[V]** "GDPNow is the closest thing in macroeconomics to an open-source forecasting model that isn't actually open source. The Atlanta Fed won't release the code — they say so plainly in the FAQ." — Medium, "Inside GDPNow"

Crucially for KONjecture, the Atlanta Fed *explicitly refuses* the comparison function: **[V]** "Because GDPNow and the New York Fed Staff Nowcast are different models, they can generate different forecasts of real GDP growth. Our policy is not to comment on or interpret any differences between the forecasts of these two models."

### 2.2 New York Fed Staff Nowcast (USA) — grade A/B (Liberty Street Economics)

> **[V]** "In April 2016, the New York Fed's Research Group launched the New York Fed Staff Nowcast, a dynamic factor model that generated estimates of current quarter GDP growth at a weekly frequency."
> **[V]** "The onset of the COVID-19 pandemic sparked widespread economic disruptions—and unprecedented fluctuations in the economic data that flow into the Staff Nowcast. This posed significant challenges to the model, leading to the suspension of publication in September 2021."
> **[V]** "Taking advantage of recent developments in time-series econometrics, we have since developed a more robust version of the Staff Nowcast model, one that better handles data volatility."

Suspended Sept 2021 → relaunched Sept 2023 ("Nowcast 2.0", weekly Friday updates). The two-year outage of one of the most prominent public nowcasts is also a demand datum (see [02](02-demand-users-and-requirements.md)).

### 2.3 OECD Weekly Tracker — grade B (OECD GitHub README + CEPR/VoxEU)

> **[V]** "The OECD Weekly Tracker of GDP growth provides a real-time high-frequency indicator of economic activity using machine learning and Google Trends data."
> **[V]** "Signals about multiple facets of the economy from Google Trends are extracted and aggregated using machine learning in order to infer a timely picture of the macro economy."
> **[V]** "Please note these are not official OECD forecasts, which are most recently published in the OECD Economic Outlook."

Coverage ~46 OECD/G20 countries; **[S]** the quarterly Google-Trends model "has a root mean squared error (RMSE) that is 37% lower than that of an autoregressive model" (CEPR VoxEU column, grade B). Code and weekly estimates are on GitHub — the closest thing to an open multi-country nowcast, but it is a research artifact (no packaging, no live service guarantee, no model comparison, no license statement found in the README).

**Update (post-mortem sweep, same day):** the Tracker has been **discontinued** — withdrawn from oecd.org to the OECD web archive, its dataset moved to the archive tenant of the OECD Data Explorer, and the GitHub repo's last push was 2022-09-20 [V — API check]. The strongest open multi-country nowcast is a dead project; see [07-graveyard-negative-cases.md](07-graveyard-negative-cases.md) case C1.

### 2.4 Deutsche Bundesbank Weekly Activity Index (Germany) — grade A

> **[V]** "The Weekly Activity Index (WAI) is an experimental measure designed to provide a timely assessment of real economic activity in Germany."
> **[V]** "The WAI can detect shifts in economic activity more promptly than many conventional official statistics, which are typically released on a monthly or quarterly basis and with a longer reporting lag."

Inputs include truck-toll mileage, electricity consumption, flights, card payments, Google searches **[S]** — direct precedent for the vision's "freight activities, mobility or news" data ambition (C7).

### 2.5 UNCTAD Nowcasts (global trade & GDP) — grade A/B

**[S]** "UNCTAD's nowcasts are data and model-based predictions of global trade and GDP period over period growth", updated weekly (UNCTAD Data Hub). The underlying library is open source (`nowcast_lstm`, below); UNCTAD research (grade B) reports **[S]** "LSTMs are found to produce superior results to Dynamic Factor Models (DFMs) in the nowcasting of global merchandise export values and volumes, and global services exports."

### 2.6 euroareanowcast.com (euro area) — grade B (academic side-project)

> **[V]** "Here we provide weekly now-cast updates for the euro area GDP."

Run by Cascaldi-Garcia (Fed Board), Ferreira (Vanguard), Giannone (Johns Hopkins), Modugno (Fed Board) **[V]**, replicating Figure 1 of their 2024 *International Journal of Forecasting* paper. Demonstrates both that academics ship such sites and how thin they stay (one region, one model, no API).

### 2.7 ESCoE regional nowcasting (UK sub-national) — grade B

> **[V]** ESCoE "produces estimates of quarterly economic growth for all UK regions to the same approximate timetable as the release of UK GVA data" using "mixed-frequency Bayesian Vector Autoregressive (BVAR) models".
> **[V]** "Timely and high-frequency regional macroeconomic indicators are essential for effective decision-making and supporting growth across the UK."

For continental Europe, sub-national nowcasting exists only as research: a mixed-frequency DFM covering **[S]** 162 NUTS2 regions in 12 European countries (*International Journal of Forecasting*, 2025; arXiv 2401.10054) — a paper, not a product.

## 3. Category B — Commercial services (the paywalled competition)

- **Now-Casting Economics** (founded by Reichlin/Giannone, the academics behind the nowcasting methodology): **[V]** "Our clients are primarily investment institutions – asset managers, hedge funds, and banks – who pay an annual subscription fee and receive our models' output data as a continuous feed." Coverage: **[V]** "models for 34 of the world's largest economies … amounting to more than 85% of the world by share of GDP."
- **Consensus Economics**: **[S]** "polls more than 700 to 1000 economists each month" across "up to 100 countries"; distribution is hard-copy/PDF/Excel under subscription (PDF delivery alone is a paid supplement of £90/US$150/€100 per year). This is the de-facto standard for *institutional forecast aggregation* (vision C4) — and it is entirely paywalled.
- **FocusEconomics**: runs annual **Analyst Forecast Awards** — **[S]** forecasters are "ranked according to the average of the absolute errors over the last 22 months" across 100+ countries. Proof that a *forecaster leaderboard* (vision C6) has commercial value; but it is annual, point-forecast-only, not vintage-correct, and closed.
- **Moody's Analytics / Oxford Economics / Capital Economics**: sell proprietary forecasts; they advertise FocusEconomics award wins prominently (grade C), confirming accuracy rankings matter reputationally.
- **MacroMicro / Trading Economics**: freemium chart aggregators that *republish* official nowcasts (GDPNow, NY Fed, WAI) — evidence of consumer demand for exactly the aggregation/comparison view, implemented shallowly and without evaluation.

## 4. Category C — Open-source model libraries

| Library | Status (verified) | Notes |
|---------|-------------------|-------|
| `dfms` (R) | **[V]** v1.0.0, 2026-01-26, GPL-3, active | **[V]** "Efficient estimation of Dynamic Factor Models using the Expectation Maximization (EM) algorithm or Two-Step (2S) estimation, supporting datasets with missing data and mixed-frequency nowcasting applications." Author blog (grade D, colour): **[V]** "dfms 1.0 thus provides a feature-rich, easy-to-use, computationally efficient (C++ powered), and verified toolset to estimate and work with DFMs in R", incl. "mixed-frequency (monthly-quarterly) DFMs … and decomposition of forecast revisions into news releases" — i.e. Bańbura–Modugno (2014), the NY-Fed-style model class. |
| `midasr` (R) | **[V]** v0.9, 2025-04-07, GPL-2\|MIT, active | **[V]** "Allows estimation, model selection and forecasting for MIDAS regressions" — second model class. |
| `nowcasting` (R) | **[V]** CRAN: "Archived on 2022-05-25 as requires archived package 'matlab'." | The R Journal-published GDP nowcasting package (Giannone et al./Bańbura et al. models) **died of an unmaintained dependency** — the key cautionary tale for sustainability. |
| `statsmodels` DynamicFactorMQ (Python) | grade B, active | **[S]** Implements Bańbura & Modugno (2014); "can allow for the nowcasting of quarterly variables based on monthly observations", with a `news` method for data-release decomposition; official notebook replicates the NY Fed model on FRED-MD/QD data. |
| `nowcast_lstm` (Python, + R/MATLAB/Julia wrappers) | grade B, single maintainer (UNCTAD-affiliated) | **[S]** "LSTM neural networks for nowcasting economic data"; used in production for UNCTAD nowcasts. Third model class (ML). |

**Implication:** vision component C1 ("different classes of models that users can choose") is essentially solved at the *estimation* layer: DFM (`dfms`/statsmodels), MIDAS (`midasr`), ML (`nowcast_lstm`). What does not exist is the harness around them — shared data interface, scheduled re-estimation, storage of every run, comparison and scoring.

## 5. Category D — Forecast-hub & evaluation infrastructure (from epidemiology)

The most complete precedent for KONjecture's comparison/evaluation half comes from infectious-disease modeling, not economics.

- **hubverse** (Consortium of Infectious Disease Modeling Hubs): **[V]** the consortium's goal is to "develop a central open-source suite of tools for creating, hosting, maintaining, and running a modeling hub", and **[V]** "the tools developed as part of this effort are designed to be more general and could be used for other purposes." Adoption (grade A, medRxiv/PMC 2025): **[S]** "used by nearly two dozen collaborative and local modeling hubs around the globe … including hubs hosted and/or used by the United States Centers for Disease Control and Prevention, the European Centre for Disease Prevention and Control, the Australia-Aotearoa Consortium for Epidemic Forecasting and Analytics, and the California Department of Public Health." Provides: standardized model-output formats (incl. quantile forecasts), submission validation, ensembling, dashboards, cloud storage.
- **Zoltar** (Reich Lab, UMass): **[S]** "a research data repository that stores time-series forecasts made by external models and provides tools for programmatic data access and scoring"; in the COVID-19 Forecast Hub case study it held "on the order of 10^8 rows" from "over 40 international research teams" (arXiv 2006.03922, grade B).
- **`scoringutils`** (epiforecasts/LSHTM): **[V]** "The `scoringutils` package facilitates the process of evaluating forecasts in R, using a convenient and flexible `data.table`-based framework." Supports binary/point/quantile/sample/nominal forecasts **[V]** and proper scoring rules; **[S]** "especially geared towards comparing multiple forecasters … and visualising results" (arXiv 2205.07090, grade B).

**Implication:** vision components C4–C6 and much of C8–C9 have a proven, funded, actively maintained open-source design to copy or adopt — just never applied to GDP.

## 6. Category E — Data infrastructure

- **DBnomics**: **[V]** "DBnomics is a free platform that aggregates publicly available economic data from national and international statistical institutions"; **[V]** "developed and maintained on a modest budget of less than €200,000 per year, funded by partner institutions"; **[V]** "already used by analysts, data scientists, and modelers in major public institutions, including the OECD, Bank of France, and the French Directorate General of the Treasury." Unified API + `rdbnomics` R client → the natural multi-country ingestion layer.
- **Real-time vintages (for vintage-correct evaluation, C6):** Philadelphia Fed Real-Time Data Set — **[S]** "consists of vintages, or snapshots, of time series of major macroeconomic variables. New vintages are added monthly"; St. Louis Fed **ALFRED** archives historical vintages with release dates **[S]**. Both are US-centric. *European/global vintage coverage is fragmented* — an open question flagged for the synthesis (evidence: Moderate; no single open cross-country vintage store surfaced in searches).
- **Institutional forecasts (open subset):** ECB **Survey of Professional Forecasters** — **[S]** "a quarterly survey of expectations for the rates of inflation, real GDP growth and unemployment in the euro area … together with a quantitative assessment of the uncertainty surrounding them", full data + microdata downloadable as CSV (grade A). US: Philadelphia Fed SPF; plus IMF WEO, OECD Economic Outlook, EC AMECO as downloadable institutional forecast sources. These make a *seed* of C4 feasible without scraping.

## 7. Category F — Application & pipeline infrastructure (R-native, per the vision's Shiny choice)

- **`targets` + `crew`** (rOpenSci): **[S]** "targets accelerates analysis with easy-to-configure parallel computing, enhances reproducibility, and reduces the burdens of repeated computation and manual data micromanagement"; it "skips costly runtime for tasks that are already up to date", and via `crew` distributes work to "traditional high-performance computing systems and cloud computing services" — directly answering the issue's "caching results, intermediate results and distributing or scheduling compute is therefore key" requirement (C8).
- **Shiny** production frameworks (`golem`, `rhino`), `pins`/Arrow/DuckDB for serving precomputed artifacts: standard, mature R stack (grade B, common knowledge; not separately quoted).

## 8. Rubric R2 — Vision coverage scores

Scores 0–3 per component (see [rubrics](00-methodology-and-rubrics.md)); C2 scored 0 = single region, 1 = few, 2 = many countries, 3 = countries + aggregates + sub-national.

| Solution | C1 models | C2 regions | C3 dashboard | C4 institutions | C5 review | C6 eval/leaderboard | C7 alt-data | C8 backend (public) | C9 OSS/extensible | **Σ/27** |
|---|---|---|---|---|---|---|---|---|---|---|
| Atlanta Fed GDPNow | 2 | 0 | 2 | 0 | 1 | 1 | 0 | 0 | 1 | **7** |
| NY Fed Staff Nowcast | 2 | 0 | 2 | 0 | 1 | 0 | 0 | 0 | 1 | **6** |
| OECD Weekly Tracker † | 2 | 2 | 1 | 0 | 1 | 0 | 2 | 0 | 2 | **10** |
| Bundesbank WAI | 1 | 0 | 1 | 0 | 0 | 0 | 3 | 0 | 1 | **6** |
| UNCTAD Nowcasts | 2 | 2 | 1 | 0 | 0 | 1 | 1 | 0 | 2 | **9** |
| euroareanowcast.com | 1 | 1 | 1 | 0 | 2 | 0 | 0 | 0 | 1 | **6** |
| ESCoE UK regions | 1 | 2 | 1 | 0 | 0 | 0 | 0 | 0 | 1 | **5** |
| Now-Casting.com 💰 | 2 | 3 | 2 | 0 | 1 | 1 | 1 | 0 | 0 | **10** |
| Consensus Economics 💰 | 0 | 3 | 0 | 3 | 1 | 1 | 0 | 0 | 0 | **8** |
| FocusEconomics 💰 | 0 | 3 | 1 | 3 | 0 | 2 | 0 | 0 | 0 | **9** |
| MacroMicro / TE 💰 | 0 | 2 | 2 | 1 | 0 | 0 | 0 | 0 | 0 | **5** |
| **hubverse** (epi domain) | 0 | 0 | 2 | 2 | 2 | 3 | 0 | 2 | 3 | **14** |
| Zoltar (epi domain) | 0 | 0 | 1 | 2 | 2 | 2 | 0 | 2 | 3 | **12** |

💰 = paywalled/commercial. † = discontinued (scored as of its operating period; see [07](07-graveyard-negative-cases.md) C1). **Reading:** the best coverage score belongs to an epidemiology toolchain with *zero* macroeconomic content; no macro offering exceeds 10/27 — and the top *open* macro scorer is now defunct; the macro offerings' strengths (C1–C3) and the epi toolchain's strengths (C4–C6, C8–C9) are *complementary*, not overlapping.

## 9. Rubric R3 — Building-block maturity (combinability)

| Building block | Maturity | Fit | Integration | License | Verdict |
|---|---|---|---|---|---|
| `dfms` | High (v1.0.0, 2026) | High (C1: DFM + news) | High (R) | GPL-3 [V] | **Adopt** |
| `midasr` | High (v0.9, 2025) | Med-High (C1: MIDAS) | High (R) | GPL-2\|MIT [V] | **Adopt** |
| statsmodels DynamicFactorMQ | High | High (C1) | Medium (Python/reticulate) | BSD-3 [S] | Adopt (2nd lang) |
| `nowcast_lstm` | Medium (single maintainer) | High (C1: ML class) | Medium (Python; R wrapper) | n/v | Adopt w/ caution |
| hubverse standards + tools | High (consortium, CDC/ECDC) | Med-High (C4–C6 design) | High (R-centric) | open source [S] | **Adopt/port** |
| `scoringutils` | High | High (C6 scoring) | High (R) | n/v (OSS) | **Adopt** |
| DBnomics + `rdbnomics` | High (institutional funding) | High (ingestion) | High (API/R) | open platform [V] | **Adopt** |
| ALFRED / Philly Fed RTDSM | High | High (C6 vintages, US) | Medium (US-centric) | public data | Adopt for US; gap elsewhere |
| ECB/Philly SPF, IMF WEO, AMECO | High | Medium (C4 seed) | Medium (heterogeneous formats) | public data | Adopt as C4 v1 |
| `targets` + `crew` | High (rOpenSci) | High (C8) | High (R) | MIT [S] | **Adopt** |
| Shiny + golem/rhino | High | High (C3; vision-mandated) | High (R) | OSS | **Adopt** |
| `nowcasting` (R pkg) | Low (CRAN-archived [V]) | — | — | — | Do **not** depend on; lesson only |

n/v = not verified in this pass.

## 10. Supply-side gaps (input to synthesis)

| # | Gap | Evidence (R5) |
|---|-----|---------------|
| G1 | **No multi-model, multi-producer comparison platform.** Producers publish single numbers; Atlanta Fed explicitly: "Our policy is not to comment on or interpret any differences…" [V] | Strong |
| G2 | **No public, continuous, vintage-correct evaluation/leaderboard for macro nowcasts.** Closest: FocusEconomics awards (commercial, annual, point-only) [S]; academic accuracy studies are static papers | Strong |
| G3 | **Institutional forecast aggregation is paywalled** (Consensus, FocusEconomics); open sources (SPF, WEO) are scattered and heterogeneous | Strong |
| G4 | **No open cross-country + sub-national nowcast coverage**; sub-national exists only as UK service (ESCoE) and an EU research paper | Strong |
| G5 | **Real-time vintage data infrastructure outside the US is fragmented** — no open ALFRED-equivalent spanning Europe/global | Moderate (absence-of-evidence after targeted search) |
| G6 | **Sustainability fragility of academic OSS** in this niche (`nowcasting` archived over a trivial dependency [V]; OECD Tracker unlicensed research repo; euroareanowcast.com a side-project) | Strong |
| G7 | **"Research article → new model variant" pipeline exists nowhere**; fully greenfield (and speculative) | Strong (absence) |

## References

| Ref | Source (grade) |
|---|---|
| 1 | [Atlanta Fed — GDPNow explainer](https://www.atlantafed.org/research-and-data/data/gdpnow/explainer) (B) [V] |
| 2 | [Atlanta Fed — GDPNow](https://www.atlantafed.org/cqer/research/gdpnow) (B) [S] |
| 3 | [Liberty Street Economics — Reintroducing the New York Fed Staff Nowcast](https://libertystreeteconomics.newyorkfed.org/2023/09/reintroducing-the-new-york-fed-staff-nowcast/) (A/B) [V] |
| 4 | [NY Fed — Staff Nowcast](https://www.newyorkfed.org/research/policy/nowcast) (B) [S] |
| 5 | [OECD Weekly Tracker GitHub (Woloszko)](https://github.com/NicolasWoloszko/OECD-Weekly-Tracker) (B) [V] |
| 6 | [CEPR VoxEU — Tracking GDP using Google Trends and machine learning](https://cepr.org/voxeu/columns/tracking-gdp-using-google-trends-and-machine-learning-new-oecd-model) (B) [S] |
| 7 | [Woloszko (2024) — Nowcasting with panels and alternative data: The OECD weekly tracker, IJF](https://www.sciencedirect.com/science/article/abs/pii/S0169207023001139) (A) [S] |
| 8 | [Bundesbank — Weekly activity index for the German economy](https://www.bundesbank.de/en/statistics/economic-activity-and-prices/weekly-activity-index/weekly-activity-index-for-the-german-economy-833976) (A) [V] |
| 9 | [Bundesbank — New indicator provides timely picture](https://www.bundesbank.de/en/tasks/topics/new-indicator-provides-timely-picture-of-macroeconomic-situation-833526) (A) [S] |
| 10 | [UNCTAD Data Hub — Nowcasts](https://unctadstat.unctad.org/EN/Nowcasts.html) (A) [S] |
| 11 | [UNCTAD Research Paper — Economic Nowcasting with LSTM](https://unctad.org/publication/economic-nowcasting-long-short-term-memory-artificial-neural-networks-lstm) (B) [S] |
| 12 | [euroareanowcast.com](https://www.euroareanowcast.com/) (B) [V] |
| 13 | [ESCoE — Regional nowcasting in the UK](https://www.escoe.ac.uk/projects/regional-nowcasting-in-the-uk/) (B) [V] |
| 14 | [Koop et al. — Nowcasting economic activity in European regions, IJF / arXiv:2401.10054](https://arxiv.org/pdf/2401.10054) (A) [S] |
| 15 | [Now-Casting Economics — About](https://now-casting.com/about.html) (C) [V] |
| 16 | [Consensus Economics — Forecast surveys / delivery](https://www.consensuseconomics.com/forecast-surveys/) (C) [S] |
| 17 | [FocusEconomics — Awards methodology](https://www.focus-economics.com/best-economic-forecaster-awards/) (C) [S] |
| 18 | [CRAN — dfms](https://cran.r-project.org/package=dfms) (B) [V] |
| 19 | [CRAN — midasr](https://cran.r-project.org/package=midasr) (B) [V] |
| 20 | [CRAN — nowcasting (archived)](https://cran.r-project.org/package=nowcasting) (B) [V] |
| 21 | [The R Journal — Nowcasting: An R Package…](https://journal.r-project.org/articles/RJ-2019-020/) (A) [S] |
| 22 | [Krantz — Releasing dfms 1.0 (blog)](https://sebkrantz.github.io/Rblog/2026/01/29/releasing-dfms-1-0-fast-and-feature-rich-estimation-of-dynamic-factor-models-in-r/) (D) [V] |
| 23 | [statsmodels — DynamicFactorMQ docs](https://www.statsmodels.org/stable/generated/statsmodels.tsa.statespace.dynamic_factor_mq.DynamicFactorMQ.html) (B) [S] |
| 24 | [nowcast_lstm GitHub (Hopp)](https://github.com/dhopp1/nowcast_lstm) (B) [S] |
| 25 | [hubverse — About](https://hubverse.io/about.html) (B) [V] |
| 26 | [Hubverse consortium paper, medRxiv/PMC 2025](https://www.medrxiv.org/content/10.1101/2025.10.03.25337284v1) (A) [S] |
| 27 | [Reich et al. — The Zoltar forecast archive, arXiv:2006.03922](https://arxiv.org/abs/2006.03922) (B) [S] |
| 28 | [scoringutils — package site](https://epiforecasts.io/scoringutils/) (B) [V] |
| 29 | [Bosse et al. — Evaluating Forecasts with scoringutils in R, arXiv:2205.07090](https://arxiv.org/abs/2205.07090) (B) [S] |
| 30 | [DBnomics — About](https://db.nomics.world/about) (B) [V] |
| 31 | [Philadelphia Fed — Real-Time Data Set for Macroeconomists](https://www.philadelphiafed.org/surveys-and-data/real-time-data-research/real-time-data-set-for-macroeconomists) (A) [S] |
| 32 | [St. Louis Fed — ALFRED](https://alfred.stlouisfed.org/) (A) [S] |
| 33 | [ECB — Survey of Professional Forecasters](https://www.ecb.europa.eu/stats/ecb_surveys/survey_of_professional_forecasters/html/index.en.html) (A) [S] |
| 34 | [targets manual — Distributed computing (crew)](https://books.ropensci.org/targets/crew.html) (B) [S] |
| 35 | [targets — overview vignette](https://cran.r-project.org/web/packages/targets/vignettes/overview.html) (B) [S] |
| 36 | [Medium — Inside GDPNow (Curry)](https://medium.com/@brian-curry-research/inside-gdpnow-a-complete-reverse-engineering-of-the-feds-most-watched-nowcast-adcfeaf0afe6) (D) [V] |
