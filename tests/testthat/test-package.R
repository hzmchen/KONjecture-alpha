# X10 (CLAUDE.md ground rule 1): core functionality lives in the konjecture
# R package; pipeline/_targets.R, ingest/ and site/ scripts are thin usage layers.

pkg_dir <- file.path(Sys.getenv("KONJ_ROOT"), "konjecture")

test_that("konjecture package has the standard layout", {
  expect_true(file.exists(file.path(pkg_dir, "DESCRIPTION")))
  expect_true(file.exists(file.path(pkg_dir, "NAMESPACE")))
  d <- read.dcf(file.path(pkg_dir, "DESCRIPTION"))
  expect_equal(unname(d[1, "Package"]), "konjecture")
  expect_true(all(c("data.table", "nanoparquet") %in%
    trimws(strsplit(d[1, "Imports"], ",")[[1]])))
})

test_that("NAMESPACE exports the core API used by the usage layers", {
  ns <- readLines(file.path(pkg_dir, "NAMESPACE"), warn = FALSE)
  api <- c(
    # pipeline/_targets.R
    "read_monthly", "read_gdp", "transform_monthly", "nowcast_quarter",
    "ar_benchmark", "dfm_bridge", "as_model_output", "append_model_output",
    "run_build_script", "render_dashboard",
    "score_first_release", "score_summary", "write_scores",
    # site/build_site.R + site/dashboard.qmd
    "build_context", "render_page", "site_main",
    "chart_evolution", "chart_trackrecord", "chart_errors", "scores_table"
  )
  for (fn in api)
    expect_true(any(grepl(sprintf("export(%s)", fn), ns, fixed = TRUE)),
                info = paste("missing export:", fn))
})

test_that("the package loads as a package and its functions are callable", {
  skip_if_not_installed("pkgload")
  pkgload::load_all(pkg_dir, quiet = TRUE)
  expect_true("konjecture" %in% loadedNamespaces())
  expect_equal(konjecture::quarters_ahead(as.Date("2026-05-15"), "2026Q2"), 0L)
  expect_equal(as.character(konjecture::horizon_bucket(0L)), "nowcast")
})

test_that("legacy core-code locations are gone (no drift between two copies)", {
  root <- Sys.getenv("KONJ_ROOT")
  expect_false(file.exists(file.path(root, "pipeline", "R", "functions.R")))
  expect_false(file.exists(file.path(root, "pipeline", "R", "scoring.R")))
  expect_false(file.exists(file.path(root, "site", "R", "site_lib.R")))
})
