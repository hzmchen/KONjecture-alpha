# Test coverage

Computed 2026-07-06 via `Rscript tests/coverage.R` (`covr::file_coverage` over 4 test files; run `Rscript tests/run_tests.R` for the pass/fail report).

| File | Line coverage |
|---|---|
| `ingest/build_archive.R` | 96.7% |
| `ingest/download_raw.R` | 92.1% |
| `pipeline/R/functions.R` | 100.0% |
| `site/R/site_lib.R` | 100.0% |
| **Total** | **98.1%** |

Excluded from instrumentation (execution glue, exercised end-to-end by `targets::tar_make()` and the golden-page regression test): `site/build_site.R`, `pipeline/_targets.R`, `tests/`.

Tests run fully offline: download success/failure paths are exercised via `file://` URLs and a refused localhost connection, never the real providers. Remaining uncovered lines are (a) the `--file=`/`getwd()` root-resolution fallbacks, which only fire in script context, and (b) defensive guards in the ECB/GDPNow parsers for malformed sections that the committed cache cannot trigger — kept as protection against future upstream format changes.
