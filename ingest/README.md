# Ingestion layer (N4 — archive seeding)

Two stages, strictly separated:

1. **`download_raw.py`** — network stage. One polite GET per source into `data/raw/` with SHA256 + retrieval-time manifest. Idempotent: cached files are never re-fetched unless `--refresh`. Run rarely and deliberately (dependency-register discipline, [08 §4](../research/08-pre-mortem.md)).
2. **`build_archive.py`** — pure local transform `data/raw/ → data/archive/{forecasts,outcomes}.{parquet,csv}` per [docs/schema.md](../docs/schema.md). Deterministic; safe to re-run anytime.

## Source register (per-source dependency register seed, pre-mortem countermeasure)

| Source id | What is ingested | Units | Known fragility | Fallback |
|---|---|---|---|---|
| `gdpnow` | Full daily nowcast history 2011Q3→ (TrackingDeepArchives + TrackingArchives) **and** BEA advance estimates + release dates (TrackRecord) → `outcomes` | SAAR % | URL moved under `/-/media/Project/...` at some point; sheet names stable for years | ALFRED series GDPNOW (needs free API key) |
| `nyfed` | Weekly nowcast grid from the 2023-relaunch xlsx (2022-12→) | SAAR % | The 2016–2021 era lives in a *different* legacy file — **not yet ingested** (gap documented) | Wayback of the old interactive's download |
| `spf_philly` | Mean current-quarter forecast `drgdp2` per round, 1968Q4→ | SAAR % | `forecast_date` approximated as the 15th of the round's middle month (exact deadlines are in a separate documentation file) | Philly Fed publishes exact deadline dates; ingest later for D1-grade timing |
| `spf_ecb` | Mean GDP point forecast per round & target period, 1999Q1→ (both calendar years `2026` and rolling quarters `2026Q4`) | **yoy %** — not convertible to q/q; `value_qq` is null by design | Section parsing of a sectioned CSV (headers: INFLATION / CORE / GROWTH / UNEMPLOYMENT / ASSUMPTIONS); a leaked-section bug was caught by sanity check — keep the spot checks | ECB Data Portal SPF dataset (API) |

## Deliberately deferred (with reasons)

- **ALFRED vintages** (all US outcome vintages beyond `advance`, e.g. second/third/latest): requires a free API key; the *schema* already accommodates them (`release_label`, `published_on`). → biggest N4 residual; unlocks `fixed_h<k>` target rules for the US (D2).
- **EA outcomes** (Eurostat preliminary-flash/flash first prints): needed before any EA scoring; candidate source: Eurostat SDMX one-off pull. Also feeds D1's EA mapping.
- **NY Fed 2016–2021 era file**: separate legacy download; ingest when found — schema-compatible.

## Validation habits that caught real bugs

Every build prints per-source row counts and date spans; after any parser change, spot-check one hand-verifiable number per source against the raw file (e.g. GDPNow's final 2026Q1 nowcast 1.2392 vs TrackRecord; ECB 2026Q2-round individuals ~0.8–1.3 ⇒ mean ≈ 0.96, *not* 3.4 — the 3.4 came from unemployment rows leaking through a bad section boundary). Validation attention is the bottleneck (P-B); these checks are cheap and stay.
