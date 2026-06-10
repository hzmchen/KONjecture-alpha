# Rebuilding Vintages from Past Publications: Feasibility Assessment

**Research date:** 2026-06-10 (v2) · Quote tags [V]/[S], grades A–D per [00](00-methodology-and-rubrics.md).

**Question:** can the point-in-time archive — the project's long-term moat ([03 §3](03-synthesis-market-gap-and-fit.md)) — be seeded *retroactively* from past publications, instead of starting at day 0?

**Answer: yes, substantially.** Two distinct things need reconstructing, and both are far more available than v1 assumed:

- **(a) Input-data vintages** — what was known when → enables honest *backtests of our own models* years into the past.
- **(b) Past forecasts by institutions/models** — who predicted what when → seeds the *comparison/review/leaderboard* immediately.

## 1. Inventory of reconstructable sources

### (a) Input-data vintages

| Source | Coverage | Span | Effort |
|--------|----------|------|--------|
| **ALFRED** (St. Louis Fed) | thousands of US series, vintage-dated with release dates; **[S]** "provides the historical vintages of the variables, including the date of each macroeconomic release" | from 1990s (series-dependent) | Low — bulk download + API |
| **Philadelphia Fed Real-Time Data Set** | major US macro variables; **[S]** "consists of vintages, or snapshots, of time series … New vintages are added monthly" | quarterly vintages back to 1965 | Low — curated files |
| **Bundesbank "Gerda" real-time database** | **[V]** "historical vintages of about 280 economic indicators" "from the national accounts, the monthly business and labour market surveys, as well as the price statistics"; **[V]** "allows a precise reconstruction of the information base at a given point in time in the past" | **[V]** vintages "available in their entirety from May 2005 (national accounts) / November 2005 (monthly indicators)"; key variables back to start of all-German reporting | Low–Medium — web exports |
| **ECB Real-Time Database (RTD / EABCN)** | **[S]** "vintages, or snapshots, of time series of more than 200 macroeconomic variables, based on series reported in the ECB's [Monthly/Economic] Bulletin"; on the ECB Data Portal; **[S]** "updated semi-annually" | vintages from January 2001 | Medium — semi-annual cadence limits freshness; fine for backtesting |
| Eurostat / national statistical offices | flash-estimate press releases (PDF) for GDP first prints | 2000s+ | Medium–High — AI-assisted PDF parsing (cheap under P-B), one-off |
| Wayback Machine | snapshots of any statistical release page | patchy | High variance — fallback only |

### (b) Past forecasts by institutions and models

| Source | What you get | Span | Effort |
|--------|--------------|------|--------|
| **Atlanta Fed GDPNow** | complete forecast history: **[S]** spreadsheet tabs "TrackingDeepArchives" (2011Q3–2014Q1), "TrackingArchives" (2014Q2→), and "TrackRecord" comparing "historical GDPNow forecasts with actual BEA advance real GDP growth estimates"; additionally vintage-archived in **[S]** ALFRED "from Q3 2011" | 2011→ | **Low — already packaged** |
| **NY Fed Staff Nowcast** | historical nowcast data published as downloadable spreadsheet (2016–2021 era and 2023→ relaunch) | 2016→ (gap 2021–23) | Low |
| **IMF WEO database vintages** | full database archived **per edition** (April + Sept/Oct rounds); **[S]** "current vintage highlighted and past vintages archived"; plus a curated panel of WEO forecasts for **[S]** "196 countries from 1990 to 2024" (Data in Brief, grade A) | 1990→ | Low–Medium |
| **ECB SPF** | **[S]** quarterly survey incl. "a quantitative assessment of the uncertainty"; full historical data + microdata as CSV | 1999→ | Low |
| **Philadelphia Fed SPF** | US professional forecasts, full history | 1968→ | Low |
| **OECD Economic Outlook editions** | projections per edition, archived databases | 1990s→ | Medium |
| **EC AMECO / European Commission forecasts** | forecast rounds (spring/autumn) published with data appendices | 1990s→ | Medium |
| Central-bank projection publications (Bundesbank, BoE fan charts, …) | semi-annual projection vintages in bulletins/PDFs | varies | Medium–High — AI-assisted PDF extraction, one-off per institution |
| Wayback Machine | defunct or unarchived forecast pages | patchy | High variance — last resort |

## 2. Assessment

| Dimension | Verdict |
|-----------|---------|
| **US backtesting** | Excellent: ALFRED + Philly Fed vintages and GDPNow/NY Fed/SPF histories give 10–50 years of vintage-correct ground truth and competitor forecasts, essentially download-ready |
| **Germany / euro area** | Good: Gerda (2005→) and ECB RTD (2001→) cover exactly the vintage-reconstruction need; SPF + WEO + OECD/AMECO cover institutional forecasts. ~20 years of backtest depth |
| **Other countries** | Mixed: WEO/OECD forecasts exist globally, but *data* vintages thin out fast outside US/EA — backtests there are degraded (latest-vintage-only), which must be disclosed per region |
| **Harmonization risk** | The real cost is not acquisition but harmonization: definition changes (ESA95→ESA2010), chain-linking breaks, base-year switches, publication-timestamp precision, mixed PDF/Excel/SDMX formats. Under P-B, parsers are cheap to write; **validation attention is the bottleneck** — budget it deliberately |
| **Legal** | Published macro statistics and forecasts are facts; compiling them is standard research practice (the entire real-time literature does this). EU database rights warrant a light check before bulk *redistribution* of any single provider's full database; storing derived/forecast-error series is unproblematic |

**Bottom line [Strong]:** the moat argument in v1 ("an archive cannot be reconstructed later") was too pessimistic about the *past* — for the US, Germany, and the euro area, a decade-plus of point-in-time history is reconstructable in weeks of spare-time effort, not years. The moat going *forward* still holds for everything not covered by these archives (e.g. weekly granularity between official vintages, sources that publish without archiving). Implication: **the leaderboard/Review mode can ship with real historical content from v0.2**, which removes the cold-start problem and is the single most differentiating cheap win.

**Direct input to Issue #2 (target measure):** the GDPNow "TrackRecord" precedent evaluates against **BEA *advance* estimates** (first publication) [S], while academic studies often target later vintages; the reconstructed archives contain *all* vintages, so the schema should store target-as-of-vintage and make the headline target a presentation choice. See the issue for the decision.

## 3. Recommended first moves (feeds [TODO](../TODO.md))

1. Ingest GDPNow spreadsheet + ALFRED GDPNOW vintages; NY Fed xlsx → first two institutional tracks, ~zero parsing risk.
2. Ingest ECB SPF + Philly SPF CSVs → survey benchmark tracks with uncertainty.
3. Ingest IMF WEO vintage databases → global annual/semi-annual coverage.
4. Gerda + ECB RTD pulls → vintage-correct German/euro-area input data for own-model backtests.
5. Defer: PDF-parsing of national projection bulletins; Wayback reconstruction (icebox until a concrete gap justifies it).

## References

| Ref | Source (grade) |
|---|---|
| 1 | [ALFRED — Archival FRED](https://alfred.stlouisfed.org/) (A) [S] |
| 2 | [ALFRED — GDPNow series vintages](https://alfred.stlouisfed.org/series?seid=GDPNOW) (A) [S] |
| 3 | [Philadelphia Fed — Real-Time Data Set for Macroeconomists](https://www.philadelphiafed.org/surveys-and-data/real-time-data-research/real-time-data-set-for-macroeconomists) (A) [S] |
| 4 | [Bundesbank — Macroeconomic real-time database (Gerda)](https://www.bundesbank.de/en/statistics/time-series-databases/-/macroeconomic-real-time-database-622290) (A) [V] |
| 5 | [Bundesbank — Gerda technical documentation](https://www.bundesbank.de/resource/blob/614976/f0a87b965de03cae73bbfbb589ddc8d2/mL/research-data-aggregate-data-real-time-database-data.pdf) (B) [S] |
| 6 | [ECB Data Portal — Real Time Database (RTD)](https://data.ecb.europa.eu/data/datasets/rtd/data-information) (A) [S] |
| 7 | [Giannone, Henry, Lalik, Modugno — An area-wide real-time database for the euro area, ECB WP 1145](https://www.econstor.eu/bitstream/10419/153579/1/ecbwp1145.pdf) (A) [S] |
| 8 | [Atlanta Fed — GDPNow (downloads incl. archives & TrackRecord)](https://www.atlantafed.org/cqer/research/gdpnow) (B) [S] |
| 9 | [NY Fed — Staff Nowcast historical data (xlsx)](https://www.newyorkfed.org/medialibrary/Research/Interactives/Data/NowCast/Downloads/New-York-Fed-Staff-Nowcast_download_data.xlsx) (A/B) [S] |
| 10 | [IMF — WEO databases (vintage archive)](https://www.imf.org/en/publications/sprolls/world-economic-outlook-databases) (A) [S] |
| 11 | [IMF WEO macroeconomic forecasts panel dataset — Data in Brief](https://www.sciencedirect.com/science/article/pii/S2352340924007662) (A) [S] |
| 12 | [ECB — Survey of Professional Forecasters (all data)](https://www.ecb.europa.eu/stats/ecb_surveys/survey_of_professional_forecasters/html/all_data.en.html) (A) [S] |
