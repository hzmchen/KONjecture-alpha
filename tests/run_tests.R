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
# core functionality lives in the konjecture package (CLAUDE.md ground rule 1);
# load_all(export_all = TRUE) also exposes internal helpers to the tests
pkgload::load_all(file.path(TEST_ROOT, "konjecture"), quiet = TRUE)

res <- test_dir(file.path(TEST_ROOT, "tests", "testthat"), stop_on_failure = TRUE)
