# Estimation Libraries, Benchmarks, Seasonal Adjustment (C1 models)

**Verified 2026-06-10** from CRAN/PyPI/GitHub ([method](README.md)). Architecture rule ([03 §5](../03-synthesis-market-gap-and-fit.md)): estimation cores are *load-bearing science* → **adopt as dependency**; every model sits behind a thin adapter emitting quantile forecasts in hubverse model-output format.

## 1. Core model classes (first adapters)

| Component | Capabilities | Status [V] | License [V] | Availability | Verdict |
|---|---|---|---|---|---|
| **`dfms`** (R) | DFM estimation via EM/2S, mixed-frequency (M/Q) nowcasting, missing data, **news decomposition of forecast revisions** (Bańbura–Modugno / NY-Fed model class); C++ core | **1.0.0, 2026-01-26** — active, recent major release | GPL-3 | CRAN; **WASM binary available [V]** | **Adopt** — model class 1 (DFM) |
| **`midasr`** (R) | MIDAS regression estimation, model selection, forecasting | 0.9, 2025-04-07 | GPL-2 \| MIT | CRAN; WASM ✓ | **Adopt** — model class 2 (MIDAS) |
| `statsmodels` `DynamicFactorMQ` (Python) | Bańbura–Modugno EM with monthly/quarterly mix, `news()` release decomposition; official notebook replicates NY Fed model | 0.14.6 (PyPI) — institutional, active | BSD-3 | PyPI; via `reticulate` | Adopt as **second-language cross-check** of `dfms` (X3) |
| `nowcast_lstm` (Python) | LSTM nowcasting; production-used by UNCTAD | 0.2.7 (PyPI); GitHub last push **2024-05** — single maintainer, quiet 2 y | MIT (repo) | PyPI + R/MATLAB/Julia wrappers | Adopt **w/ caution** — model class 3 (ML), behind adapter only |
| `nowcastLSTM` (R wrapper) | reticulate wrapper for the above | last push 2024-05; **no license file detected in repo [V]** | **n/v — flag** | GitHub only | Prefer calling the Python pkg via own thin reticulate glue (P-B) over depending on an unlicensed wrapper |

## 2. Benchmarks and second-line candidates (include-rather-than-exclude)

| Component | Capabilities | Status [V] | License [V] | Availability | Verdict |
|---|---|---|---|---|---|
| `fable` + `fabletools` (tidyverts) | AR/ARIMA/ETS/VAR benchmarks, distributional forecasts, tidy interface | 0.5.0 (2026-01-23) / 0.7.0 (2026-04-30) — active | GPL-3 | CRAN; WASM ✓ | **Adopt for the AR benchmark** (N2) — distributional output maps cleanly to quantiles |
| `forecast` | Classic Hyndman benchmark suite (predecessor of fable) | 9.0.2, 2026-03-18 — maintained | GPL-3 | CRAN; WASM ✓ | Alternative if fable friction appears |
| `midasml` | High-dimensional MIDAS via sparse-group LASSO (Babii–Ghysels–Striaukas) | 0.1.11, 2025-10-09 | GPL ≥2 | CRAN; WASM ✓ | Watch — candidate 4th class (regularized high-dim) |
| `sparseDFM` | DFMs with sparse loadings (EM); ESCoE-lineage | 1.0, 2023-03-23 — single release, quiet | GPL ≥3 | CRAN; WASM ✓ | Watch — interpretable-loadings variant |
| `KFAS` | Exponential-family state-space models, Kalman filtering | 1.6.0, 2025-05-26 | GPL-2\|3 | CRAN; WASM ✓ | Escape hatch for custom state-space models |
| `MARSS` | Multivariate AR state-space with EM | 3.11.10, 2025-09-10 | GPL-2 | CRAN | Same niche as KFAS; optional |

## 3. Seasonal adjustment (only if ingesting NSA series)

| Component | Capabilities | Status [V] | License [V] | Availability | Verdict |
|---|---|---|---|---|---|
| `seasonal` | X-13ARIMA-SEATS interface (via `x13binary`) | 1.10.0, 2024-10-19 | GPL-3 | CRAN | Default if SA is ever needed; most target series arrive seasonally adjusted |
| `RJDemetra` | JDemetra+ (official EU SA method: TRAMO/SEATS, X-13) | 0.2.8, 2024-12-12 | **EUPL** | CRAN; needs Java | Optional; EUPL is GPL-compatible |
| `rjd3toolkit` | JDemetra+ v3 generation | 3.7.1, 2026-03-10 — active | EUPL | CRAN | Successor track of RJDemetra; watch |

## 4. Graveyard — verified CRAN removals (do not depend; lessons)

| Package | CRAN status [V] | Lesson |
|---|---|---|
| `nowcasting` | "Archived on 2022-05-25 as requires archived package 'matlab'" | The known cautionary tale ([01 §4](../01-supply-existing-frameworks.md)) |
| `nowcastDFM` | "Archived on 2022-05-25 as requires archived package 'matlab'" — **same dependency killed two packages** | One trivial dependency took out the *entire* CRAN GDP-nowcasting niche in one day |
| `mfbvar` | "Archived on 2022-08-08 as issues were not corrected in time"; repo dormant since 2021-05 | **Mixed-frequency BVAR is now an unowned model class in R.** Opportunity note: a vendored/AI-ported MF-BVAR adapter is a differentiating candidate — icebox until X3 |

## 5. Layer assessment

- C1 is **solved at the estimation layer** with three live, license-clean, adapter-ready classes (DFM / MIDAS / ML) plus a tidy benchmark stack — confirming [01 §4](../01-supply-existing-frameworks.md) with 2026-fresh data.
- Surprising bonus: **every R estimation candidate, including C++-based `dfms`, has a webR/WASM binary** [V] — estimation stays in the offline pipeline regardless ([05 §3](../05-shiny-risks-and-alternatives.md)), but this removes a whole class of future constraint (e.g. small in-browser demo refits).
- GPL-3 cores ⇒ distribute the combined work under a GPL-3-compatible license ([README §headline 5](README.md)).

## References

CRAN canonical pages, fetched 2026-06-10 [V]; [PyPI statsmodels](https://pypi.org/project/statsmodels/), [PyPI nowcast-lstm](https://pypi.org/project/nowcast-lstm/) [V]; GitHub [dhopp1/nowcast_lstm](https://github.com/dhopp1/nowcast_lstm), [dhopp1/nowcastLSTM](https://github.com/dhopp1/nowcastLSTM), [ankargren/mfbvar](https://github.com/ankargren/mfbvar) [V]; WASM: [repo.r-wasm.org](https://repo.r-wasm.org/) PACKAGES index (R 4.5) [V].
