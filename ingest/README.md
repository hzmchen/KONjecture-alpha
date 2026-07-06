# Ingestion layer (N4 — archive seeding)

Two stages, strictly separated (pure R; the original Python implementation was ported 2026-07-06 and validated output-identical against it):

1. **`download_raw.R`** — network stage. One polite GET per source into `data/raw/` with SHA256 + retrieval-time manifest (`Rscript ingest/download_raw.R [--refresh] [--only id …]`). Idempotent: cached files are never re-fetched unless `--refresh`. Run rarely and deliberately (dependency-register discipline, [08 §4](../research/08-pre-mortem.md)); it is intentionally **not** part of the `targets` graph.
2. **`build_archive.R`** — pure local transform `data/raw/ → data/archive/{forecasts,outcomes}.{parquet,csv}` per [docs/schema.md](../docs/schema.md). Deterministic; safe to re-run anytime — standalone (`Rscript ingest/build_archive.R`) or as part of `targets::tar_make()` in [pipeline/](../pipeline/README.md), which tracks raw files → archive → site.

## Source register (per-source dependency register seed, pre-mortem countermeasure)

| Source id | What is ingested | Units | Known fragility | Fallback |
|---|---|---|---|---|
| `gdpnow` | Full daily nowcast history 2011Q3→ (TrackingDeepArchives + TrackingArchives) **and** BEA advance estimates + release dates (TrackRecord) → `outcomes` | SAAR % | URL moved under `/-/media/Project/...` at some point; sheet names stable for years | ALFRED series GDPNOW (needs free API key) |
| `nyfed` | Weekly nowcast grid from the 2023-relaunch xlsx (2022-12→) | SAAR % | Relaunch file covers 2023-era only; the publication gap 2021-09→2022-12 is real (model suspended) | — |
| `nyfed_legacy` | The retired interactive's file (2002→2021-08): real-time forecasts for targets 2016Q1→ as `nyfed`; earlier targets kept apart as **`nyfed_retro`** (retrospective estimates, never on leaderboards) | SAAR % | Frozen file (model retired 2021); URL could vanish — cached | Wayback |
| `ecb_rtd_gdp` | **EA outcome vintages**: euro-area real GDP levels, all vintages via SDMX `includeHistory` (`VALID_FROM` = publication timestamp) → q/q growth per vintage, earliest per quarter = `first_release`, 1991Q2→ | q/q % (canonical) | RTD's first capture can lag the Eurostat preliminary flash by weeks (e.g. 2025Q1 captured t+65) — **D1 caveat**: EA "first release" here = first RTD vintage, not necessarily the flash | Eurostat press-release PDFs (AI-assisted parse, deferred) |
| `spf_philly` | Mean current-quarter forecast `drgdp2` per round, 1968Q4→ | SAAR % | `forecast_date` approximated as the 15th of the round's middle month (exact deadlines are in a separate documentation file) | Philly Fed publishes exact deadline dates; ingest later for D1-grade timing |
| `spf_ecb` | Mean GDP point forecast per round & target period, 1999Q1→ (both calendar years `2026` and rolling quarters `2026Q4`) | **yoy %** — not convertible to q/q; `value_qq` is null by design | Section parsing of a sectioned CSV (headers: INFLATION / CORE / GROWTH / UNEMPLOYMENT / ASSUMPTIONS); a leaked-section bug was caught by sanity check — keep the spot checks | ECB Data Portal SPF dataset (API) |

## Deliberately deferred (with reasons)

- **ALFRED vintages** (all US outcome vintages beyond `advance`, e.g. second/third/latest): requires a free API key (owner action O3); the *schema* already accommodates them (`release_label`, `published_on`). → last N4 residual; unlocks `fixed_h<k>` target rules for the US (D2).
- **Eurostat flash first prints** (t+30 preliminary flash): EA outcome vintages are now ingested from the ECB RTD, but its first capture can lag the flash — upgrade when D1 demands flash-precision timing.
- ~~EA outcomes~~ **done 2026-07-06** via ECB RTD (14,434 vintage rows, 140 quarters).
- ~~NY Fed 2016–2021 era file~~ **done 2026-07-06** via the retired interactive's still-live URL (826 real-time rows 2015-12→, 1,288 retro rows kept apart).

## Data licensing / reuse register (pre-mortem countermeasure, [08 §4](../research/08-pre-mortem.md))

Published macro statistics and forecasts are facts and compiling them is standard research
practice ([06 §2](../research/06-vintage-reconstruction.md)); this register tracks the
per-provider terms that matter before any bulk *redistribution*.

| Provider | Terms page | Status |
|---|---|---|
| ECB (RTD, SPF) | [ECB Data Portal reuse: CC BY 4.0](https://data.ecb.europa.eu/help/copyright-and-disclaimer) | attribution required — compatible with redistribution |
| FRED (fredgraph csv) | [FRED terms of use](https://fred.stlouisfed.org/legal/) | cite source; **verify before redistributing bulk series** (we redistribute only 6 cached series for reproducibility) |
| Atlanta Fed (GDPNow) | [frbatlanta.org terms](https://www.atlantafed.org/disclaimers-and-terms-of-use) | public research data; attribution customary; verify before bulk redistribution |
| NY Fed (Staff Nowcast) | [newyorkfed.org terms of use](https://www.newyorkfed.org/termsofuse) | public research data; attribution customary; verify before bulk redistribution |
| Philadelphia Fed (SPF) | [SPF data page](https://www.philadelphiafed.org/surveys-and-data/real-time-data-research/survey-of-professional-forecasters) | public research data; attribution customary |

Derived tables in `data/archive/` (normalized values, growth rates, errors) are
compilations/derived series — unproblematic per the legal note in 06 §2. The raw cache is
redistributed solely for reproducibility, unmodified, with provenance in `manifest.json`.

## Validation habits that caught real bugs

Every build prints per-source row counts and date spans; after any parser change, spot-check one hand-verifiable number per source against the raw file (e.g. GDPNow's final 2026Q1 nowcast 1.2392 vs TrackRecord; ECB 2026Q2-round individuals ~0.8–1.3 ⇒ mean ≈ 0.96, *not* 3.4 — the 3.4 came from unemployment rows leaking through a bad section boundary). Validation attention is the bottleneck (P-B); these checks are cheap and stay.

The R port was validated row-for-row against the Python build's outputs. One known, accepted difference: the ECB 2000Q3-round mean for target 2002 is **2.9222** (exact mean 2.92225; R's half-even rounding at the 4th decimal is correct where Python's float `round()` gave 2.9223).
