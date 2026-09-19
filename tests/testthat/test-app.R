# X5 shinylive skeleton: the app is a thin usage layer over tested konjecture
# functions; here we only check it assembles and constructs. The in-browser
# WASM boot is a manual smoke test (site/app/README.md) — browsers don't fit
# in the offline suite.

test_that("export.R assembles a self-contained app dir from repo artifacts", {
  root <- Sys.getenv("KONJ_ROOT")
  env <- new.env()
  sys.source(file.path(root, "site/app/export.R"), envir = env)  # guard keeps it side-effect free
  staging <- env$assemble_app(root)
  expect_true(all(file.exists(file.path(staging,
    c("app.R", "R/site_lib.R", "data/forecasts.parquet", "data/outcomes.parquet",
      "data/scores_summary.parquet", "data/manifest.json")))))
  unlink(staging, recursive = TRUE)
})

test_that("the app constructs against the real archive", {
  skip_if_not_installed("shiny")
  root <- Sys.getenv("KONJ_ROOT")
  env <- new.env()
  sys.source(file.path(root, "site/app/export.R"), envir = env)
  staging <- env$assemble_app(root)
  owd <- setwd(staging); on.exit({setwd(owd); unlink(staging, recursive = TRUE)})
  app <- shiny::shinyAppFile("app.R")
  expect_s3_class(app, "shiny.appobj")
})
