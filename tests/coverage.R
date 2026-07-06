#!/usr/bin/env Rscript
# Coverage: Rscript tests/coverage.R
# covr::file_coverage over the four logic files (thin entry scripts
# site/build_site.R and pipeline/_targets.R are execution glue, exercised by
# `tar_make()` itself, and are excluded from instrumentation). Writes
# tests/COVERAGE.md.

arg <- grep("--file=", commandArgs(FALSE), value = TRUE)
ROOT <- normalizePath(file.path(dirname(sub("--file=", "", arg[1])), ".."))
Sys.setenv(KONJ_ROOT = ROOT)
setwd(ROOT)

suppressMessages(library(data.table))
library(testthat)

sources <- c("ingest/download_raw.R", "ingest/build_archive.R",
             "site/R/site_lib.R", "pipeline/R/functions.R")
tests <- list.files("tests/testthat", pattern = "^test-.*[.]R$", full.names = TRUE)

cov <- covr::file_coverage(sources, tests)
print(cov)
total <- covr::percent_coverage(cov)

by_line <- covr::tally_coverage(cov, by = "line")
per_file <- aggregate(value ~ filename, by_line, function(v) 100 * mean(v > 0))
per_file <- per_file[order(per_file$filename), ]

md <- c(
  "# Test coverage",
  "",
  sprintf("Computed %s via `Rscript tests/coverage.R` (`covr::file_coverage` over %d test files; run `Rscript tests/run_tests.R` for the pass/fail report).",
          format(Sys.Date()), length(tests)),
  "",
  "| File | Line coverage |",
  "|---|---|",
  sprintf("| `%s` | %.1f%% |", per_file$filename, per_file$value),
  sprintf("| **Total** | **%.1f%%** |", total),
  "",
  "Excluded from instrumentation (execution glue, exercised end-to-end by `targets::tar_make()` and the golden-page regression test): `site/build_site.R`, `pipeline/_targets.R`, `tests/`.",
  "",
  "Tests run fully offline: download success/failure paths are exercised via `file://` URLs and a refused localhost connection, never the real providers. Remaining uncovered lines are (a) the `--file=`/`getwd()` root-resolution fallbacks, which only fire in script context, and (b) defensive guards in the ECB/GDPNow parsers for malformed sections that the committed cache cannot trigger — kept as protection against future upstream format changes."
)
writeLines(md, "tests/COVERAGE.md")
cat(sprintf("\nTOTAL: %.1f%% -> tests/COVERAGE.md\n", total))
