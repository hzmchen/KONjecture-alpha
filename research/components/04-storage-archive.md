# Storage & Archive (the moat: append-only forecast + vintage archive; C5/C6 substrate, C8)

**Verified 2026-06-10** from CRAN / repo.r-wasm.org ([method](README.md)). Requirement recap: append-only, file-based (no database server — dormancy), readable from both the offline pipeline and the static/WASM view layer, escrow-able ([08 §4](../08-pre-mortem.md) Zenodo snapshots).

## 1. Formats and engines

| Component | Capabilities | Status [V] | License [V] | Availability | Verdict |
|---|---|---|---|---|---|
| **`nanoparquet`** | Zero-dependency parquet read/write for data-frame-shaped data | 0.5.1, 2026-04-20 — active (Posit/Csárdi) | MIT | CRAN; **WASM ✓** | **Adopt as the app-side parquet reader** and candidate pipeline writer — smallest dependency surface in the catalog |
| **`duckdb`** | In-process SQL over parquet/CSV, larger-than-memory analytics, zero server | 1.5.2, 2026-04-13 — active, foundation-backed | MIT | CRAN; **WASM ✓** (plus the separate DuckDB-WASM JS project) | **Adopt for queries** over the archive (leaderboard cuts, vintage joins) — in-process = no standing infra |
| `arrow` | Full Arrow ecosystem: datasets, partitioned parquet, S3, dplyr backend | 24.0.0, 2026-04-29 — active (Apache) | Apache-2 | CRAN; **no WASM binary [V] — the only stack package missing one** | Adopt **pipeline-side only** (heavy C++ binary; also a `hubData` dependency). Never required app-side thanks to nanoparquet/duckdb |
| `pins` | Versioned artifact publishing (board on GitHub/S3/folder) | 1.4.2, 2026-03-09 | Apache-2 | CRAN | Optional sugar; plain versioned parquet in-repo may suffice — decide at N2 |
| `qs2` | Fast R-native serialization (a `targets` storage format) | 0.2.2, 2026-06-03 — active | GPL-3 | CRAN | Optional for internal pipeline caches only — **never for the archive** (R-only format violates openness/escrow) |

## 2. Archive pattern (recommendation)

1. **Canonical store = append-only parquet**, hive-partitioned by source and vintage/run date, living in the repo (or a data branch) — readable by R, Python, DuckDB, and browsers; survives any single package's death (parquet has ≥3 independent R readers above).
2. **Write path:** pipeline (`targets`) writes via `nanoparquet` (preferred, minimal) or `arrow` (if partitioned-dataset ergonomics earn their weight). **Read path:** dashboard reads `nanoparquet`/`duckdb`-WASM — the `arrow` WASM gap makes this split mandatory, and it is exactly the static-first split [05 §3](../05-shiny-risks-and-alternatives.md) already prescribes.
3. **Schema** must record outcome-as-of-vintage (pending [Issue #2](https://github.com/hzmchen/KONjecture-alpha/issues/2)) and follow hubverse model-output columns for forecasts ([03 §1](03-formats-validation-scoring.md)).

## 3. Escrow / long-term availability

| Component | Capabilities | Status | Licensing/cost | Verdict |
|---|---|---|---|---|
| **Zenodo** | DOI-minting archival snapshots (50 GB/record), GitHub-release integration | CERN-operated, EU-funded, running since 2013 | free; CC/any license per deposit | **Adopt** for code+archive snapshots per release ([08 §4](../08-pre-mortem.md) X8) |
| GitHub Releases | Versioned artifact attachments (2 GB/file) | platform | free, no DOI | Complement, not substitute (no DOI, platform-dependent) |

## 4. Layer assessment

- This layer is the **healthiest in the whole catalog**: three independent, MIT/Apache-licensed, actively maintained parquet implementations mean the archive — the project's stated moat ([03 §3](../03-synthesis-market-gap-and-fit.md)) — has no single point of software failure.
- The one verified gap (`arrow` lacks a WASM binary) is fully routed around by `nanoparquet`/`duckdb` and only reinforces the precomputed-artifacts invariant.

## References

CRAN canonical pages, fetched 2026-06-10 [V]; WASM: [repo.r-wasm.org](https://repo.r-wasm.org/) PACKAGES index (R 4.5) [V]; [Zenodo — about/infrastructure](https://about.zenodo.org/) (A) [S].
