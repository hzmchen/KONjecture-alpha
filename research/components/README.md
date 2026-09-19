# Component Research — Solutions per Target-Architecture Layer

**Research date:** 2026-06-10 · Addresses [Issue #3](https://github.com/hzmchen/KONjecture-alpha/issues/3) · Architecture baseline: [03 §5](../03-synthesis-market-gap-and-fit.md) (components C1–C9, "combine the plumbing, rebuild the glue") and the static-first delivery decision in [05 §3](../05-shiny-risks-and-alternatives.md).

**Method.** For every candidate component: key capabilities, project status (version, release date, maintenance signal), licensing, and availability. Per the issue: *when in doubt, include rather than exclude* — borderline candidates appear with a "watch/optional" verdict instead of being dropped. All Version / Published / License fields were fetched 2026-06-10 from canonical machine-readable sources (grade A, tagged **[V]**): CRAN package pages, the GitHub REST API (`pushed_at`, `archived`, license), PyPI JSON, the hubverse r-universe API, and the webR binary index `repo.r-wasm.org` (R 4.5 tree, 23,559 packages). Capability one-liners are paraphrased from official descriptions (**[S]**). Verdicts apply the [R3 maturity rubric](../00-methodology-and-rubrics.md) and the v2 adoption rule from [03 §5](../03-synthesis-market-gap-and-fit.md): **adopt** institutionally maintained load-bearing science, **adopt-as-standard** formats, **rebuild with AI** thin glue.

## Files ↔ architecture layers

| File | Layer | Vision components |
|---|---|---|
| [01-data-access](01-data-access.md) | Data-access clients (APIs, SDMX, vintage stores) | C2, C4, C6-input |
| [02-models-estimation](02-models-estimation.md) | Estimation libraries, benchmarks, seasonal adjustment | C1 |
| [03-formats-validation-scoring](03-formats-validation-scoring.md) | Hub formats, submission validation, scoring | C4, C5, C6, C9 |
| [04-storage-archive](04-storage-archive.md) | Archive formats, query engines, artifact escrow | C5/C6 archive, C8 |
| [05-pipeline-orchestration](05-pipeline-orchestration.md) | Pipeline, compute, reproducibility, CI scheduling | C8 |
| [06-view-layer-delivery](06-view-layer-delivery.md) | Dashboard, WASM deployment, charting, hosting | C3 |

Data *sources* (series, vintages, institutional forecast files) are inventoried in [06-vintage-reconstruction](../06-vintage-reconstruction.md) and [01 §6](../01-supply-existing-frameworks.md); this directory covers the *software* that touches them.

## Headline findings

1. **The full intended stack exists, is currently maintained, and is license-compatible.** Every "Adopt" block from R3 checked out as alive in June 2026: `dfms` 1.0.0, `midasr` 0.9, `scoringutils` 2.2.0, `targets` 1.12.0, `crew` 1.3.1, `shiny` 1.13.0, hubverse 13-package suite (all MIT). No load-bearing component is archived, orphaned, or pre-1.0 except where flagged.
2. **TODO N5 (webR/WASM audit) is effectively answered — positively.** Of 32 stack packages checked against `repo.r-wasm.org`, **31 have pre-built WASM binaries — including C++-based `dfms`, `midasr`, `scoringutils`, `duckdb`, and `nanoparquet`. The only miss is `arrow`**, which is fully substitutable browser-side by `nanoparquet`/`duckdb`. The shinylive default deployment ([05 §3](../05-shiny-risks-and-alternatives.md)) is viable. Details: [06-view-layer-delivery §3](06-view-layer-delivery.md).
3. **The graveyard predicted the right failure mode: this layer's rot vector is provider-API churn and single-maintainer decay, concentrated in *data clients* and *niche estimation* packages.** Newly verified CRAN removals: `nowcastDFM` (2022, same `matlab` dependency death as `nowcasting`), `mfbvar` (2022, "issues were not corrected in time" — the mixed-frequency BVAR model class is now unowned in R), `wiesbaden` (2025, maintainer request). Successors exist (`restatis` for Destatis, `bbk` for Bundesbank/ECB) — the catalog tracks both.
4. **The hubverse is mostly off-CRAN.** Only `hubUtils` and `hubEnsembles` are on CRAN; `hubData`, `hubValidations`, `hubEvals`, `hubAdmin`, `hubVis` install from the hubverse r-universe. Consequence for a dormancy-tolerant project: pin via `renv` lockfile with the r-universe repo URL, or vendor — and prefer *formats over code* exactly as [03 §5](../03-synthesis-market-gap-and-fit.md) recommends.
5. **Two licensing notes, neither blocking:** `rdbnomics` is AGPL-3 (copyleft reaches code that imports it — fine for an open project, or call the DBnomics HTTP API directly); GPL-3 estimation cores (`dfms`, `fable`) mean a combined distributed work should carry a GPL-compatible license.
