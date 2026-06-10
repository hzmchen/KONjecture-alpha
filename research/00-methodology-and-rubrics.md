# Research Methodology & Assessment Rubrics

**Project:** KONjecture-alpha — open-source platform serving and comparing real-time GDP nowcasts across regions (see [Issue #1 "Product Vision Draft"](https://github.com/hzmchen/KONjecture-alpha/issues/1)).
**Research date:** 2026-06-10.
**Method:** Web search + direct retrieval of primary sources (official institution pages, package documentation, peer-reviewed papers, vendor sites). Findings are documented per topic: supply ([01](01-supply-existing-frameworks.md)), demand ([02](02-demand-users-and-requirements.md)), synthesis ([03](03-synthesis-market-gap-and-fit.md)), summary ([04](04-summary.md)).

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

---

## Scope notes & limitations

- Searches were conducted in English; German/French-language offerings (e.g. national institutes' tools) may be under-represented. The German "Konjunktur" ecosystem (ifo, IfW, DIW, Bundesbank) was checked via English sources.
- Commercial vendors do not publish pricing; paywall evidence is therefore partly indirect (subscription pages, supplement fees).
- Web search result snippets occasionally paraphrase; that is exactly why the [V]/[S] tagging exists.
