# The Graveyard: Negative Cases of Comparable Projects

**Research date:** 2026-06-10 (v2 addendum) · Quote tags [V]/[S], grades A–D per [00](00-methodology-and-rubrics.md). This document closes the **survivorship-bias gap** flagged in [00 — limitations] and TODO X6: v1 searched for evidence the vision is wanted; this sweep deliberately searched for **comparable projects that died**, to learn *how* such things fail. Companion: [08-pre-mortem.md](08-pre-mortem.md).

**Method:** targeted searches in three rings — (1) macro nowcast products, (2) adjacent real-time data/forecast dashboards (epidemiology, prices, media), (3) base rates from the open-source substrate. Causes of death are graded; where a cause is inferred rather than documented, it is marked as such.

## 1. Case files

### Ring 1 — macro nowcasting

| # | Case | Lifespan | What happened | Cause (evidence) |
|---|------|----------|---------------|------------------|
| C1 | **OECD Weekly Tracker** | 2020 → discontinued | The flagship alt-data GDP nowcast (46 countries, Google Trends + ML) is **no longer updated and has been withdrawn from oecd.org** — its page now lives on `web-archive.oecd.org`; the dataset is served from the OECD *archive* tenant; the third-party platform Alphacast files it under "discontinued" [S]. The companion GitHub repo's **last push was 2022-09-20** [V — GitHub API, checked 2026-06-10] | Not publicly documented. Pattern consistent with **champion departure / institutional priority shift** after the COVID impulse faded (inferred — Moderate). Note the repo was *personal* (`NicolasWoloszko/…`), not an `OECD/` org repo: bus factor 1 inside a large institution |
| C2 | **NY Fed Staff Nowcast** (suspension) | 2016 → **suspended 2021–2023** → relaunched | **[V]** "The onset of the COVID-19 pandemic sparked widespread economic disruptions—and unprecedented fluctuations in the economic data … leading to the suspension of publication in September 2021" | **Credibility protection under model stress**: the institution preferred two years of silence over publishing numbers it distrusted (Strong, A/B source). Resurrection required a methodological rebuild |
| C3 | **`nowcasting` R package** | 2017 → archived 2022 | **[V]** CRAN: "Archived on 2022-05-25 as requires archived package 'matlab'." The R-Journal-published GDP nowcasting package died of an unmaintained *utility dependency* | **Dependency cascade** + maintainer attention lapse (Strong). Same mechanism recurs across CRAN, e.g. `survivalAnalysis`, archived 2025 "as requires the archived package 'tidytidbits'" [S] |
| C4 | **Billion Prices Project** (MIT/Harvard) | 2008 → ended (datasets stop 2020) | Pioneering real-time online-price inflation measurement; the academic project ended; **[S]** its data collection lives on only inside **PriceStats, "a private company now part of State Street's Data Intelligence unit"** | **Academic lifecycle**: PIs move on; the survival path was commercialization (Strong). For a Liebhaberei that path is unavailable *and* unwanted — the lesson is the archive's afterlife, not the business |

### Ring 2 — adjacent real-time dashboards

| # | Case | Lifespan | What happened | Cause (evidence) |
|---|------|----------|---------------|------------------|
| C5 | **JHU Coronavirus Resource Center** | 2020-01-22 → 2023-03-10 | The world's most-cited pandemic dashboard — **[V]** "surpassing 2.5 billion website views as it provided the public, journalists, and policymakers across the nation and around the world with reliable, real-time information" — **[V]** "ceased collecting and reporting COVID-19 data … three years after the institution embarked on the unprecedented effort". Data **[V]** "will remain free and accessible … for all data reported between Jan. 22, 2020, and March 10, 2023" | **Upstream data decay + official alternatives + cost**: states cut public reporting, CDC/WHO trackers matured, home tests degraded case data [S, multiple A/B sources]. A *planned, well-archived* shutdown — the "good death" exemplar |
| C6 | **COVID Tracking Project** (The Atlantic) | 2020-03 → 2021-03-07 | Volunteer data compilation powering countless downstream tools. **[V]** "No one expected a volunteer pop-up collective to publish and interpret public health data for the United States for the first year of a global pandemic. We began the work out of necessity and planned to do it for a couple of weeks at most, always in the expectation that the federal public health establishment would make our work obsolete." **[V]** "the work itself … is properly the work of federal public health agencies." **[V]** "They've borrowed time from other work, quit jobs, postponed graduate degrees, and missed time with their families. More than 400 people have contributed directly … It's time to release these brilliant people back to their lives." | **Volunteer unsustainability, consciously managed**: real-time data compilation at institutional scale burns people; the team *chose* an end date, documented replacements, archived everything (Strong, [V]) |
| C7 | **Rt.live** | 2020-04 → ~2021 | High-profile Rt model dashboard (Systrom/Krieger/Vladeck); stopped updating around when its data source died: **[S]** "As of March 7, 2021 the COVID Tracking Project was no longer collecting new data" | **Upstream-dependency death chain** (Moderate — inferred timing): a model dashboard is only as alive as its input feed |
| C8 | **Google Flu Trends** | 2008 → shut 2015 | The original alt-data nowcast. **[S — verbatim per course copy of the *Science* article]** "'Big data hubris' is the often implicit assumption that big data are a substitute for, rather than a supplement to, traditional data collection and analysis"; GFT "missed high for 100 out of 108 weeks starting with August 2011". Google's search algorithm changed **[S]** "86 times in June and July 2012 alone" — the input was a moving target | **Input drift + accuracy shock** (Strong, A source: Lazer, Kennedy, King & Vespignani, *Science* 343:1203, 2014). Canonical warning for alt-data inputs (supports icebox I4) |
| C9 | **FiveThirtyEight** | 2008 → shut 2025-03-05 | Data-journalism/forecasting institution shut by ABC/Disney cost cuts [S — Nieman Lab]; founder had left in 2023 taking the model rights. Worse: **[S]** in May 2026 ABC redirected thousands of archived articles, making them inaccessible; Silver reported ABC would not sell him the IP "for any price" | **Owner/platform risk + archive destruction after death** (Strong for the shutdown; Moderate/C-grade for motives). The anti-exemplar of C5/C6: value evaporated because the archive was owner-controlled |

### Ring 3 — base rates (the substrate)

- **[S]** Tidelift's State of the Open Source Maintainer survey (2024): "60% of maintainers remain unpaid", "60% have quit or considered quitting" maintaining a project, 44% citing burnout; among unpaid maintainers, **61% maintain their projects alone** (grade C — vendor research, widely cited; directionally robust).
- CRAN archival is routine and frequently *cascading* (C3 and its echo in other fields): a package's life expectancy is bounded by its least-maintained dependency.

## 2. Failure taxonomy

| ID | Mechanism | Cases | KONjecture exposure |
|----|-----------|-------|---------------------|
| T1 | **Upstream data death/decay** | C5, C7; (C8 as drift) | High — the whole product is downstream of statistical offices and third-party archives |
| T2 | **Dependency cascade** | C3, `survivalAnalysis` | Medium — directly addressed by thin-deps policy (P-B) |
| T3 | **Champion departure / priority shift** | C1, C4, (C9) | **Maximal — the project *is* one champion** |
| T4 | **Accuracy/credibility shock** | C8, C2 | Medium — any published number can be wrong in public |
| T5 | **Volunteer/maintainer exhaustion** | C6, Ring-3 base rates | High — 61%-solo, 44%-burnout base rates describe exactly this project |
| T6 | **Funding/owner cost cuts** | C9, (C5 partial) | Low — no owner, ~no costs by design |
| T7 | **Archive loss after death** | C9; counterexamples C5/C6 | Avoidable — this is a *choice* made before death |

## 3. What the graveyard teaches (input to the [pre-mortem](08-pre-mortem.md))

1. **Nothing here died of competition or lack of demand.** Every case had users — JHU had 2.5bn views. Deaths came from inputs, attention, owners, and credibility. The v1–v2 market analysis optimized for the wrong risk if read as "build it and sustain it"; sustainability is an *input/attention* problem.
2. **Even giants stop. Plan the death, don't deny it.** C5/C6 show a project's value survives a *well-executed* shutdown (announce, archive, document replacements); C9 shows value being destroyed retroactively by an owner-controlled archive. → pre-written sunset protocol; data and code in forkable, openly licensed repos; escrow snapshots (e.g. Zenodo DOIs).
3. **A "real-time" product that silently stops updating is worse than one that declares dormancy.** C1's tracker pages quietly moved to an archive tenant; nothing on the GitHub repo says "ended". → staleness must be self-announcing (last-updated banner, automatic dormant-mode notice).
4. **Institutional backing is not a sustainability plan** (C1, C4, C9) — and a personal repo inside a big institution is still bus-factor 1 (C1). The honest unit of planning is the individual's attention, which is the Liebhaberei premise anyway.
5. **Alt-data inputs are moving targets** (C8: 86 algorithm changes in two months). Confirms icebox I4 with the strongest possible precedent.
6. **The suspension option** (C2): a credible project may *pause* output rather than publish junk — but only if its architecture and communications make pausing cheap and dignified.

## References

| Ref | Source (grade) |
|---|---|
| 1 | [OECD web archive — Weekly Tracker section](https://web-archive.oecd.org/sections/weekly-tracker-of-gdp-growth/index.htm) (B) [S] |
| 2 | [OECD Data Explorer (archive tenant) — Weekly Tracker dataset](https://data-explorer.oecd.org/vis?tenant=archive&df%5Bds%5D=DisseminateArchiveDMZ&df%5Bid%5D=DF_ECO_TRACKER3&df%5Bag%5D=OECD) (B) [S] |
| 3 | [Alphacast — OECD Tracker dataset marked "discontinued"](https://www.alphacast.io/datasets/discontinued-activity-global-oecd-tracker-of-economic-activity-weekly-37863) (C) [S] |
| 4 | GitHub API, `NicolasWoloszko/OECD-Weekly-Tracker` `pushed_at: 2022-09-20` (B) [V] |
| 5 | [Liberty Street Economics — Reintroducing the NY Fed Staff Nowcast](https://libertystreeteconomics.newyorkfed.org/2023/09/reintroducing-the-new-york-fed-staff-nowcast/) (A/B) [V] |
| 6 | [CRAN — nowcasting (archived)](https://cran.r-project.org/package=nowcasting) (B) [V] · [CRAN Survival task view (archived pkgs)](https://cran.r-project.org/web/views/Survival.html) (B) [S] |
| 7 | [Wikipedia — MIT Billion Prices project](https://en.wikipedia.org/wiki/MIT_Billion_Prices_project) (C) [S] · [Cavallo & Rigobon, JEP 2016](https://www.aeaweb.org/articles?id=10.1257%2Fjep.30.2.151) (A) [S] · [PriceStats](https://www.pricestats.com/news) (C) [S] |
| 8 | [JHU Hub — Johns Hopkins COVID-19 data hub ends after three years (2023-03-10)](https://hub.jhu.edu/2023/03/10/coronavirus-resource-center-data-hub-ends/) (B) [V] |
| 9 | [NPR — As the pandemic ebbs, an influential COVID tracker shuts down](https://www.npr.org/sections/health-shots/2023/02/10/1155790201/as-the-pandemic-ebbs-an-influential-covid-tracker-shuts-down) (B) [S] |
| 10 | [COVID Tracking Project — "It's Time: The COVID Tracking Project Will Soon Come to an End"](https://covidtracking.com/analysis-updates/covid-tracking-project-end-march-7) (B) [V] |
| 11 | [Lazer, Kennedy, King, Vespignani — The Parable of Google Flu: Traps in Big Data Analysis, *Science* 343 (2014)](https://gking.harvard.edu/publications/parable-google-flu%C2%A0traps-big-data-analysis) (A) [S — definition verbatim via course copy of the article] |
| 12 | [Time — Google Flu Trends Big Data Problems](https://time.com/23782/google-flu-trends-big-data-problems/) (C) [S] |
| 13 | [Nieman Lab — FiveThirtyEight is shutting down (2025-03-05)](https://www.niemanlab.org/2025/03/fivethirtyeight-is-shutting-down-as-part-of-broader-cuts-at-abc-and-disney/) (B) [S] |
| 14 | [Editor & Publisher — Thousands of FiveThirtyEight articles seemingly vanish](https://www.editorandpublisher.com/stories/thousands-of-fivethirtyeight-articles-seemingly-vanish-from-the-internet,261686) (C) [S] · [Silver — Disney erased FiveThirtyEight](https://www.natesilver.net/p/disney-erased-fivethirtyeight) (C/D) [S] |
| 15 | [Tidelift — Maintainer burnout is real](https://blog.tidelift.com/maintainer-burnout-is-real) (C) [S] · [Tidelift press release, 2024 survey](https://tidelift.com/about/press-releases/survey-finds-many-open-source-maintainers-are-stressed-out-and-underpaid-but-persist-so-they-can-make-a-positive-impact) (C) [S] |
