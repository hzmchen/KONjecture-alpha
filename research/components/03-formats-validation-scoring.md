# Hub Formats, Submission Validation, Scoring (C4 collect, C5 review, C6 evaluate, C9 extensibility)

**Verified 2026-06-10** from CRAN / hubverse r-universe API / GitHub ([method](README.md)). Architecture rule ([03 §5](../03-synthesis-market-gap-and-fit.md)): hubverse **formats are adopted as a standard**; the implementing packages are adopted only where they pull their weight — they can be thinly reimplemented if they don't fit macro.

## 1. hubverse suite (Consortium of Infectious Disease Modeling Hubs)

13 packages, **all MIT-licensed [V]**, consortium-backed (CDC/ECDC adoption evidence in [01 §5](../01-supply-existing-frameworks.md)). Active: pushes to core repos within days of this check [V].

| Package | Capabilities | Version [V] | Availability | Relevance |
|---|---|---|---|---|
| `hubUtils` | Core utilities, **model-output format** handling | 1.2.0, 2026-01-13 | **CRAN**; WASM ✓ | **Adopt as standard-bearer** — defines the quantile-forecast schema every KONjecture model adapter emits |
| `hubData` | Access/query hub data (arrow-backed) | 2.2.1 | r-universe | Adopt if archive layout follows hub conventions; note `arrow` dependency (see [04 §1](04-storage-archive.md)) |
| `hubValidations` | Submission validation framework (schema + content checks) | 2.1.0 | r-universe | Adopt when external submissions ever open (X-phase); until then own forecasts just conform to schema |
| `hubEnsembles` | Ensemble methods over hub model outputs | 1.0.0, 2025-05-23 | **CRAN**; WASM ✓ | Adopt for a simple ensemble track (proven hub value-add) |
| `hubEvals` | Score hub forecasts (wraps scoringutils) | 0.2.0 — pre-1.0 | r-universe | Watch; may be thin enough to bypass in favor of `scoringutils` directly |
| `hubAdmin` | Hub configuration administration | 1.9.0 | r-universe | Only if running a *real* multi-party hub; not needed for v0 |
| `hubVis` | Plotting for hub outputs | 0.1.3 — pre-1.0 | r-universe | Optional |
| (`hubExamples`, `hubDevs`, `hubStyle`, `hubCI`, `hubverse` meta, `hubPredEvalsData`) | examples/dev tooling | various | r-universe | Reference only |

**Operational caveat:** only `hubUtils` and `hubEnsembles` are on CRAN; the rest install from `hubverse-org.r-universe.dev`, whose binaries track GitHub HEAD. For dormancy tolerance, pin exact versions in the `renv` lockfile (r-universe supports versioned source tarballs) or vendor the few functions actually used — consistent with "adopt the format, not necessarily the code".

## 2. Zoltar (design precedent, not dependency)

| Component | Capabilities | Status [V] | License [V] | Availability | Verdict |
|---|---|---|---|---|---|
| Zoltar server (`reichlab/forecast-repository`) | Forecast repository with API + scoring; held ~10⁸ rows for 40+ teams ([01 §5](../01-supply-existing-frameworks.md)) | last push 2025-04 | GPL-3 | GitHub (Django app) | **Do not deploy** — a running server is the anti-R7 shape ([05 RS1](../05-shiny-risks-and-alternatives.md)). Mine its schema/API design |
| `zoltr` (R client) | Programmatic access to a Zoltar instance | 1.0.2, 2025-03-06 | GPL-3 | CRAN; WASM ✓ | Only if ever federating with an existing Zoltar instance; otherwise N/A |

## 3. Scoring & evaluation

| Component | Capabilities | Status [V] | License [V] | Availability | Verdict |
|---|---|---|---|---|---|
| **`scoringutils`** (epiforecasts) | Forecast evaluation framework: WIS, CRPS, calibration, pairwise model comparison, data.table-based | **2.2.0, 2026-04-05** — active, post-2.0 stable API | MIT | CRAN; WASM ✓ | **Adopt** — the C6 core (X2) |
| `scoringRules` | The underlying proper-scoring-rule math (CRPS/LogS for parametric + sample forecasts); academic reference implementation | 1.1.3, 2024-09-18 | GPL-2\|3 | CRAN; WASM ✓ | Adopt transitively (scoringutils dep); direct use for sample-based CRPS |
| `murphydiagram` | Murphy diagrams for elementary-score decomposition (Ehm et al.) | 0.12.2, **2019-12-06 — dormant** | GPL-3 | CRAN | Optional diagnostic; tiny and self-contained, so dormancy is tolerable — include-don't-rely |

## 4. Layer assessment

- The comparison/evaluation half of the architecture rests on **two healthy pillars**: hubverse formats (MIT, consortium) for *interoperability* and `scoringutils` (MIT, active) for *scoring science*. Both verified current; both WASM-available, so even browser-side score exploration is possible.
- The schema decision in [Issue #2](https://github.com/hzmchen/KONjecture-alpha/issues/2) (target vintage) is *orthogonal* to the hubverse format: model-output format fixes *forecast* representation; the archive must additionally store outcome-as-of-vintage ([06 §2](../06-vintage-reconstruction.md)).
- Residual risk is the r-universe distribution channel (§1 caveat) — mitigated by pinning/vendoring, and far smaller than the value of format compatibility with the only proven multi-model forecast-hub ecosystem.

## References

CRAN canonical pages, fetched 2026-06-10 [V]; [hubverse r-universe API](https://hubverse-org.r-universe.dev/api/packages) [V]; GitHub API for `hubverse-org/*`, `reichlab/forecast-repository` [V]; [hubverse docs](https://docs.hubverse.io/) (B) [S].
