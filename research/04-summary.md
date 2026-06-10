# High-Level Summary — Market Research for KONjecture-alpha

**Date:** 2026-06-10 (v2 same day) · Full detail: [methodology/rubrics](00-methodology-and-rubrics.md) · [supply](01-supply-existing-frameworks.md) · [demand](02-demand-users-and-requirements.md) · [synthesis](03-synthesis-market-gap-and-fit.md) · [Shiny risks & alternatives](05-shiny-risks-and-alternatives.md) · [vintage reconstruction](06-vintage-reconstruction.md) · [TODO/next steps](../TODO.md). All quotes in the detailed documents are source-validated and graded.

> **v2 context:** the project is a one-person Liebhaberei built with AI assistants (premises P-A/P-B in [00](00-methodology-and-rubrics.md)). The findings below stand; the decision lens changed — see "Verdict (v2)".

## The vision (Issue #1, in one line)

An open-source R Shiny platform that **serves, compares, and evaluates real-time GDP nowcasts** across regions, combining user-selectable model classes with collected institutional forecasts, uncertainty visualization, past-forecast review, and vintage-correct performance leaderboards.

## Supply — what exists

- **Single-producer nowcasts are plentiful and popular** (Atlanta Fed GDPNow, NY Fed Staff Nowcast, OECD Weekly Tracker, Bundesbank WAI, UNCTAD, ESCoE UK regions) — but each publishes **one number from one model**, and producers explicitly refuse to compare themselves ("Our policy is not to comment on or interpret any differences between the forecasts of these two models" — Atlanta Fed).
- **Comparison and aggregation are paywalled** (Consensus Economics, FocusEconomics, Now-Casting Economics — whose clients "pay an annual subscription fee") or shallow (MacroMicro/Trading Economics chart republishing).
- **Every building block exists in mature open source**: estimation (`dfms` 1.0, `midasr`, statsmodels `DynamicFactorMQ`, `nowcast_lstm`), data (DBnomics, FRED/ALFRED, SPF), evaluation (`scoringutils`), pipeline (`targets`/`crew`), and — crucially — **forecast-hub architecture from epidemiology** (hubverse/Zoltar, used by CDC and ECDC).
- In our 27-point vision-coverage scoring, **no macro offering scores above 10; the epidemiology hubverse scores 14 with zero macro content**. Macro strengths and hub strengths are perfectly complementary.

## Demand — who wants it

Demand for nowcasts is proven four ways: a paying commercial market; heavily followed free trackers ("GDPNow fills an important economic information gap" — Atlanta Fed); continued public-sector investment (≈80% of central banks formally discuss big data, nowcasting the top use case — BIS); and felt gaps when products vanish (NY Fed's two-year suspension). Segment scoring (rubric R4): **financial professionals are Tier 1 pull; academics and official-sector economists are the realistic early community** (highest open-source adoption and contribution potential); regional policymakers' demand is documented ("a key demand from stakeholders" — ESCoE) but harder to serve. The unserved requirement cluster is precisely **comparison, review, and accountability** (R-5/6/7).

## Selling points (open source)

1. **Free what is paywalled** — cross-country nowcasts + institutional forecast comparison.
2. **Actually open** — GDPNow's "methodology is open; the implementation is closed"; KONjecture can be the first end-to-end open GDP nowcast (BIS: open-sourcing models brings "enhanced predictability, accountability, streamlined collaboration").
3. **The neutral comparison venue** no producer will build.
4. **A continuous, vintage-correct leaderboard** — commercially validated (FocusEconomics awards), scientifically validated in epidemiology (hubverse), absent in macro.

## Verdict (v2)

**The market gap is the hub, not the models** — and the unserved jobs are *compare* (J2) and *hold accountable* (J3), both served by the same artifact: an archive of point-in-time forecasts plus a comparison view. Gap ranking (R6, now a gated screen): ① comparison platform, ② institutional-forecast aggregation from free sources, ③ vintage-correct evaluation/leaderboard — whose feasibility *rose* in v2: per-country vintage stores already exist (ALFRED, Bundesbank Gerda, ECB RTD) and major forecast histories are downloadable (GDPNow, NY Fed, IMF WEO, SPF), so **backtesting need not start at day 0** ([06](06-vintage-reconstruction.md)). Sub-national, alt-data, scraping, and the paper-to-model pipeline are iceboxed with explicit revisit triggers ([TODO](../TODO.md)).

**Decision lens (Liebhaberei + AI-assisted):** success criterion is founder fit (rubric R7: curiosity, learning, energy return, dormancy tolerance, affordable loss), not adoption. The maintainer is user #1; the most energy-giving external segment is academics/students (v2 Tier 1), not the finance users who topped the v1 market-pull ranking. **Strategy: combine the plumbing, rebuild the glue** — adopt institutionally maintained estimation/scoring/data dependencies and the hubverse *formats*, rebuild thin glue with AI rather than adopting heavy frameworks. Design every component for **graceful dormancy** (static-first delivery; Shiny kept as the hobby but deployed serverlessly via shinylive where possible, [05](05-shiny-risks-and-alternatives.md)); quarterly fun/obligation/affordable-loss audits replace adoption-deadline kill criteria.
