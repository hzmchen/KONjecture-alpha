# Test coverage

Computed 2026-07-08 via `Rscript tests/coverage.R` (`covr::file_coverage` over 9 test files; run `Rscript tests/run_tests.R` for the pass/fail report).

| File | Line coverage |
|---|---|
| `ingest/build_archive.R` | 96.8% |
| `ingest/download_raw.R` | 65.4% |
| `konjecture/R/functions.R` | 100.0% |
| `konjecture/R/models.R` | 98.2% |
| `konjecture/R/scoring.R` | 98.4% |
| `konjecture/R/site_lib.R` | 99.1% |
| `konjecture/R/weo.R` | 100.0% |
| **Total** | **94.9%** |

Excluded from instrumentation (execution glue, exercised end-to-end by `targets::tar_make()` and the golden-page regression test): `site/build_site.R`, `pipeline/_targets.R`, `tests/`.

Tests run fully offline: download success/failure paths are exercised via `file://` URLs and a refused localhost connection, never the real providers. Remaining uncovered lines are (a) the `--file=`/`getwd()` root-resolution fallbacks, which only fire in script context, (b) defensive guards in the ECB/GDPNow parsers for malformed sections that the committed cache cannot trigger — kept as protection against future upstream format changes, and (c) the real-network branches of `download_raw.R` (curl handle setup, the https candidate-URL walk), exercised only by deliberate ingestion runs.
