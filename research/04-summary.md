# High-Level Summary — Market Research for KONjecture-alpha

**Date:** 2026-06-10 · Full detail: [methodology/rubrics](00-methodology-and-rubrics.md) · [supply](01-supply-existing-frameworks.md) · [demand](02-demand-users-and-requirements.md) · [synthesis](03-synthesis-market-gap-and-fit.md). All quotes in the detailed documents are source-validated and graded.

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

## Verdict

**The market gap is the hub, not the models** — promising product–market fit for an open-source project *if* scoped accordingly. Gap-opportunity ranking (rubric R6): ① multi-model/multi-producer comparison platform (score 60), ② open institutional-forecast aggregation seeded from free sources (36), ③ vintage-correct public evaluation/leaderboard (30) — the long-term moat, since an accumulated point-in-time forecast archive cannot be forked or reconstructed. Defer sub-national coverage and alt-data; drop the paper-to-model pipeline from the roadmap (score 5).

**Recommended strategy:** combine, don't rebuild — hubverse-compatible forecast formats + `dfms`/`midasr` model adapters + DBnomics/ALFRED data + `scoringutils` scoring + `targets`/`crew` pipeline + Shiny front end reading precomputed artifacts. Start with one or two regions and an append-only archive from the first run. **Top delivery risk is maintainer sustainability** — this niche's history (CRAN-archived `nowcasting` package, unlicensed research repos, side-project sites) says governance and minimal dependencies matter more than features.
