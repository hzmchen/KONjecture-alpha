# `targets` pipeline — single entry point for the whole build

Grew out of the N2 riskiest-assumption spike (**passed**: can one person run
data pull → transform → benchmark + factor model → probabilistic output → append-only
archive, reproducibly, with zero standing infrastructure? — [TODO N2](../TODO.md)) and
now orchestrates everything downstream of the network:

```sh
cd pipeline
Rscript -e 'targets::tar_make()'
```

builds, with dependency tracking and skipping: **raw cache → normalized archive**
(`ingest/build_archive.R`) **→ nowcast models → static site** (`site/build_site.R`).
The network stage (`Rscript ingest/download_raw.R`) is deliberately *outside* the
graph — downloads happen rarely and consciously, never as a build side effect.
Model output appends to `data/archive/model_output.parquet` (+ csv mirror).
Idempotent: re-running on the same inputs and date adds nothing (keyed dedupe,
all targets skip).

## What it is — and is deliberately not

| Piece | Choice | Status |
|---|---|---|
| Orchestration | `targets` (R3 adopt) | real |
| Data | 5 monthly US indicators + GDP growth, **latest vintage** via keyless fredgraph | spike-grade: vintage-correct pulls need ALFRED (key) — the known N4 residual |
| Benchmark | AR(2) on SAAR growth, normal predictive quantiles | real, honest baseline |
| Model | `dfms::DFM` (r=2, p=2) on stationarized indicators → quarterly factor mean → OLS bridge with lagged GDP | simplest defensible factor nowcast; **not** the full mixed-frequency EM treatment (that's X3 territory) |
| Output | hubverse-style rows: point + 7 quantiles, SAAR %, `declared_target=advance` | real; feeds the same archive discipline as N4 |
| Uncertainty | in-sample residual σ, normal | placeholder — backtest-calibrated intervals arrive with X2 |

Quantile levels: 0.025, 0.1, 0.25, 0.5, 0.75, 0.9, 0.975.

## Spike verdict criteria

Success = one reproducible end-to-end `tar_make()` run on a clean checkout with the
raw cache present. Anything about model *quality* is explicitly out of scope — that
is X2's (scoring) and X3's (model classes) job.
