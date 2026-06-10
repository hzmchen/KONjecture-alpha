# Research Methodology & Assessment Rubrics

**Project:** KONjecture-alpha — open-source platform serving and comparing real-time GDP nowcasts across regions (see [Issue #1 "Product Vision Draft"](https://github.com/hzmchen/KONjecture-alpha/issues/1)).
**Research date:** 2026-06-10.
**Method:** Web search + direct retrieval of primary sources (official institution pages, package documentation, peer-reviewed papers, vendor sites). Findings are documented per topic: supply ([01](01-supply-existing-frameworks.md)), demand ([02](02-demand-users-and-requirements.md)), synthesis ([03](03-synthesis-market-gap-and-fit.md)), summary ([04](04-summary.md)).

## Context update (v2, 2026-06-10)

Two premises supplied by the project owner after v1 reframe the *decision lens* (the factual findings stand):

- **P-A — Liebhaberei.** This is a one-person side project out of curiosity, with no profit intent. Success criterion is sustained enjoyment and learning, not adoption or revenue. Consequence: expected-value logic (pick the biggest opportunity) is replaced by **effectuation logic** (start from means; risk only an affordable loss; let goals emerge) — see Sarasvathy's effectuation research. Rubrics R4 and R6 are amended below, and a new gating rubric **R7 (founder/maintainer fit)** is added.
- **P-B — AI-assisted build.** The project is developed with AI assistants, which sharply lowers the cost of *writing* code — including rebuilding components that would previously have been adopted as dependencies. It does **not** comparably lower the cost of *operating* services, monitoring scrapers, supporting users, or holding context: the scarce resource is maintainer **attention**, not lines of code. Consequence: build-vs-reuse tilts toward thin bespoke code over heavy dependencies (reducing the dependency-death risk seen with the CRAN-archived `nowcasting` package), while *standards* (e.g. hubverse model-output formats) remain worth adopting because their value is interoperability, not code. Feasibility scores in R6 are re-baselined accordingly.

v2 also adds two topic docs ([05 — R Shiny risks & alternatives](05-shiny-risks-and-alternatives.md), [06 — rebuilding vintages](06-vintage-reconstruction.md)) and a prioritized [TODO/next-steps](../TODO.md).

## How quotes were validated

Every quote in these documents is tagged with a validation level:

| Tag | Meaning |
|-----|---------|
| **[V]** | Verbatim — the source page/PDF was fetched directly on 2026-06-10 and the quote extracted from its text. |
| **[S]** | Sourced via search-engine result content attributed to the cited URL; the page itself was not separately re-fetched. Treated as reliable only when consistent with other evidence. |

No quote is reproduced from model memory alone. Where a page could not be fetched (e.g. HTTP 403), either a raw HTTP retrieval was performed or the claim was downgraded/marked [S].

---

## Rubric R1 — Source credibility

Applied to every reference in the reference lists.

| Grade | Definition | Usage rule |
|-------|-----------|------------|
| **A** | Peer-reviewed journal article, or official publication of a central bank / statistical office / international organisation (BIS, ECB, OECD, UNCTAD, ONS…) | Can carry a conclusion alone |
| **B** | Working paper, official software documentation, institutional project page, CRAN/PyPI metadata | Can carry a conclusion alone; prefer two for strong claims |
| **C** | Vendor/commercial website, reputable trade press, maintained OSS README | Supporting evidence; conclusions need corroboration |
| **D** | Personal blog, Medium post, forum | Colour/illustration only; never sole support for a conclusion |

## Rubric R2 — Vision coverage score (supply side)

Each existing solution is scored 0–3 on the nine components distilled from Issue #1:

| ID | Vision component (from the issue) |
|----|------------------------------------|
| C1 | Real-time GDP nowcast **production**, multiple model classes |
| C2 | **Multi-region** coverage: nation states, unions (EU), sub-national regions |
| C3 | Interactive **dashboard** serving forecasts incl. uncertainty, mode switching |
| C4 | **Institutional forecast collection** (central banks, research & government institutions) |
| C5 | **Past-forecast review**: expected vs. realised activity |
| C6 | **Point-in-time evaluation / leaderboard** using only data available at forecast time (vintage-correct) |
| C7 | **Innovative real-time inputs** (freight, mobility, news/opinions) besides classic macro data |
| C8 | **Backend**: storage of data/outputs/revisions, caching, scheduled/distributed compute |
| C9 | **Open source & extensible** toward a domain-agnostic forecast-evaluation framework |

Scoring: **0** = absent · **1** = partial/rudimentary · **2** = substantial · **3** = fully covers the component. Maximum 27. The score measures *coverage of the KONjecture vision*, not general quality of the solution.

## Rubric R3 — Building-block maturity (combinability)

For components that could be **reused** rather than competed with:

| Dimension | High (3) | Medium (2) | Low (1) |
|-----------|----------|------------|---------|
| **Maturity** | Active releases ≤ 12 months, institutional backing or multiple maintainers | Maintained but slow / single maintainer | Archived, unmaintained, or pre-1.0 with no activity |
| **Fit** | Directly implements a vision component | Needs adaptation | Concept transfer only |
| **Integration cost** | R-native or stable HTTP API | Cross-language bridge needed | Substantial re-implementation |
| **License** | Permissive or weak copyleft (MIT/Apache/GPL with no data restrictions) | Copyleft with implications | Restrictive / unclear / ToS-limited data |

## Rubric R4 — Demand segment attractiveness

Each candidate user segment is scored 1–5 per dimension; weighted total → tier.

| Dimension | Weight | 5 means… |
|-----------|--------|----------|
| Reach (size of segment) | 0.15 | Very large population of potential users |
| Need intensity | 0.30 | Documented, recurring, unmet need |
| Evidence strength (per R5) | 0.25 | Strong direct evidence of the need |
| OSS adoption propensity | 0.15 | Segment routinely adopts open-source tools |
| Contribution potential | 0.15 | Segment can contribute code/models/data |

Tiers: **Tier 1** ≥ 4.0 · **Tier 2** 3.0–3.9 · **Tier 3** < 3.0.

**v2 amendment (P-A).** The v1 weights answer "where is market pull strongest?" — the right question for a product, the wrong one for a Liebhaberei. For a hobby project the segments that *give energy back* matter most. v2 therefore adds a second weighting — Reach 0.10, Need 0.20, Evidence 0.15, OSS adoption 0.20, **Contribution potential 0.35** — reported alongside the v1 scores in [02-demand](02-demand-users-and-requirements.md). Additionally, **the maintainer is segment S0, the first and load-bearing user** ("scratch your own itch"); no external segment outranks S0.

## Rubric R5 — Evidence strength (per claim)

| Level | Criterion |
|-------|----------|
| **Strong** | ≥ 2 independent A/B sources, or one A source exactly on point |
| **Moderate** | One A/B source, or several consistent C sources |
| **Weak** | C/D sources only, or an indirect inference |

Conclusions in the synthesis are labelled with their evidence level; Weak-evidence claims are flagged as hypotheses to validate, not findings.

## Rubric R6 — Gap opportunity score (synthesis)

For each identified market gap:

`Opportunity = Unmet-ness (1–5) × Demand weight (Tier 1 = 3, Tier 2 = 2, Tier 3 = 1) × Feasibility for a small OSS team (1–5)`

Range 1–75. Used to rank which parts of the vision to build first; the ranking logic is shown in [03-synthesis-market-gap-and-fit.md](03-synthesis-market-gap-and-fit.md).

**Methodological caution.** R2/R4/R6 multiply and weight *ordinal* scales scored by a single rater. Treat outputs as **screening ranks, not magnitudes**; only large differences are meaningful, and rankings should survive a ±1 perturbation of any single score before being acted on (sensitivity check tracked in [TODO](../TODO.md)).

**v2 amendments (P-A, P-B).**
1. **R7 gates R6**: a high-opportunity item that fails R7 (below) goes to the icebox regardless of score.
2. **Feasibility re-baselined** to "one person + AI assistants, in spare time". This *raises* build feasibility (code is cheap) but **not** operational feasibility: standing services, scraper babysitting, support expectations, and legal review still cost scarce attention. Feasibility is now scored on the *operating* burden, not the writing burden.

## Rubric R7 — Founder/maintainer fit (v2, the gate)

Applied to every roadmap item before R6 ranking is acted on. Any item scoring **Low on Energy return or Dormancy tolerance is redesigned or iceboxed**, whatever its opportunity score.

| Criterion | Question | High / Medium / Low |
|-----------|----------|---------------------|
| Curiosity fit | Does building this answer a question the maintainer actually finds interesting? | intrinsic / partial / chore |
| Learning value | Does it teach skills or knowledge worth having independent of the project? | much / some / none |
| Energy return | After an evening on this, more or less motivated? | energizing / neutral / draining |
| **Dormancy tolerance** | Can it survive 3 untouched months without breaking, rotting, or creating obligations to strangers? | yes / degrades gracefully / breaks or embarrasses |
| Affordable loss | Is the worst case (time, money, public failure) within the accepted loss budget? | clearly / probably / no |

---

## Scope notes & limitations

- Searches were conducted in English; German/French-language offerings (e.g. national institutes' tools) may be under-represented. The German "Konjunktur" ecosystem (ifo, IfW, DIW, Bundesbank) was checked via English sources.
- Commercial vendors do not publish pricing; paywall evidence is therefore partly indirect (subscription pages, supplement fees).
- Web search result snippets occasionally paraphrase; that is exactly why the [V]/[S] tagging exists.
- **No primary research**: all evidence is secondary (web). Even 3–5 conversations (ESCoE authors, hubverse community, r/econometrics) would upgrade demand evidence from "inferred" to "heard". Tracked in [TODO](../TODO.md).
- **No systematic negative-case sweep**: v1 searched for evidence the vision is wanted, not for *dead comparable projects* (survivorship bias). The graveyard observations (CRAN-archived `nowcasting`, unlicensed research repos) were found incidentally. A deliberate search for abandoned econ dashboards plus a pre-mortem is tracked in [TODO](../TODO.md).
- **Single rater**: all rubric scores reflect one analyst pass (AI-assisted); no inter-rater check.
