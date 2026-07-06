# Archive Schema v0.1

Implements the N1 decision ([Issue #2](https://github.com/hzmchen/KONjecture-alpha/issues/2) option 4, analysis in [research/09](../research/09-target-measure-decision.md)): **every outcome row carries its own publication vintage; scores are (forecast, target-rule) pairs, never bare numbers.** Canonical unit per 09 D3: **non-annualized q/q real GDP growth in percent** (`value_qq`); the native published unit (e.g. US SAAR) is preserved alongside (`value_native`, `unit_native`), so SAAR is a display transform, not a stored truth.

## Directory layout

```
data/
  raw/                 # cached upstream files, exactly as downloaded (append-only)
    manifest.json      # per file: url, retrieved_at (UTC), sha256, bytes, notes
  archive/             # normalized append-only tables (parquet + csv mirror)
    forecasts.parquet  # who predicted what, when
    outcomes.parquet   # what was published, per outcome vintage
ingest/                # one script per source + shared download/manifest helpers
pipeline/              # N2 spike (own-model pipeline)
site/                  # N3 static comparison page + generator
```

## Table `forecasts`

One row per (source, region, target_period, forecast_date, output_type, output_id).

| Column | Type | Notes |
|---|---|---|
| `source` | str | `gdpnow`, `nyfed`, `spf_philly`, `spf_ecb`, `konjecture_<model>` … |
| `region` | str | ISO-ish: `US`, `EA` |
| `variable` | str | `rgdp_growth` for now |
| `target_period` | str | reference quarter, `2024Q1` |
| `forecast_date` | date | date the forecast was made/published (the *forecast* vintage) |
| `output_type` | str | `point` or `quantile` (hubverse-style) |
| `output_id` | str/null | quantile level (`0.05` … `0.95`) when `output_type=quantile`, else null |
| `value_native` | float | as published |
| `unit_native` | str | `saar_pct` (US), `qq_pct` (EA), `yoy_pct` |
| `value_qq` | float | canonical: non-annualized q/q %, converted from native |
| `declared_target` | str | what the producer says it predicts: `advance`, `latest`, `unspecified` — fairness metadata per [09 §4](../research/09-target-measure-decision.md) |
| `retrieved_at` | timestamp | UTC, from raw manifest |
| `source_file` | str | raw file the row was parsed from |

Unit conversions: `saar_pct → qq_pct`: ((1+s/100)^(1/4)−1)·100. `yoy` is *not* converted (not identifiable to q/q without the path) — rows keep `value_qq = null` and are excluded from q/q comparisons.

Hubverse mapping (adopt-as-standard, [03 §5](../research/03-synthesis-market-gap-and-fit.md)): `source→model_id`, `target_period→target_end_date`, `output_type/output_id/value` map 1:1 to `model_output` columns; a thin exporter can emit hubverse-format CSVs from this table.

## Table `outcomes`

One row per (region, target_period, outcome vintage). This is the table that makes any target rule computable later.

| Column | Type | Notes |
|---|---|---|
| `region`, `variable`, `target_period` | | as above |
| `release_label` | str | `advance`, `second`, `third`, `latest_YYYYMMDD`, … (`advance` = US first print; EA analog is `preliminary_flash` — D1 per-region mapping lives here) |
| `published_on` | date/null | publication date of that vintage (null when only the label is known) |
| `value_native`, `unit_native`, `value_qq` | | as in `forecasts` |
| `source`, `retrieved_at`, `source_file` | | provenance |

## Target rules (scores are computed against a named rule, never "the truth")

| Rule id | Definition | Status |
|---|---|---|
| `first_release` | earliest `release_label` per region (US: `advance`) | headline default (N1) |
| `fixed_h<k>` | vintage published k quarters after `target_period` | scientific default; k = open sub-decision D2 |
| `latest` | max `published_on` | computable, never a default (09 §2) |

Append-only discipline: ingestion may add rows, never mutate or delete; re-downloads that change history are a new `retrieved_at` generation, flagged loudly.
