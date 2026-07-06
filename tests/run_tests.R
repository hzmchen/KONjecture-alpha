#!/usr/bin/env Rscript
# Test runner: Rscript tests/run_tests.R   (from anywhere)
# Sources every R entry point (their `if (sys.nframe() == 0L)` guards keep them
# side-effect free), then runs tests/testthat/. Tests read the committed raw
# cache as fixtures and write only to tempdirs.

arg <- grep("--file=", commandArgs(FALSE), value = TRUE)
TEST_ROOT <- normalizePath(file.path(dirname(sub("--file=", "", arg[1])), ".."))
Sys.setenv(KONJ_ROOT = TEST_ROOT)

suppressMessages(library(data.table))
library(testthat)

source(file.path(TEST_ROOT, "ingest", "download_raw.R"))
source(file.path(TEST_ROOT, "ingest", "build_archive.R"))
source(file.path(TEST_ROOT, "site", "R", "site_lib.R"))
source(file.path(TEST_ROOT, "pipeline", "R", "functions.R"))
source(file.path(TEST_ROOT, "pipeline", "R", "scoring.R"))

res <- test_dir(file.path(TEST_ROOT, "tests", "testthat"), stop_on_failure = TRUE)
