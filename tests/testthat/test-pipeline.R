# pipeline/R/functions.R — model + IO functions. Real FRED csvs (committed
# cache) for data prep; synthetic series where the model property is the point.

root <- Sys.getenv("KONJ_ROOT")
monthly_path <- file.path(root, "data/raw/fred_monthly_indicators.csv")
gdp_path <- file.path(root, "data/raw/fred_gdp_growth.csv")

test_that("read_gdp labels quarters and read_monthly parses dates", {
  gdp <- read_gdp(gdp_path)
  expect_named(gdp, c("date", "gdp_saar", "quarter"))
  expect_true(all(grepl("^\\d{4}Q[1-4]$", gdp$quarter)))
  expect_identical(gdp$quarter[gdp$date == as.Date("2026-01-01")], "2026Q1")
  m <- read_monthly(monthly_path)
  expect_s3_class(m$observation_date, "Date")
  expect_true(all(c("INDPRO", "PAYEMS", "RSAFS", "UNRATE", "DGORDER") %in% names(m)))
})

test_that("transform_monthly stationarizes from 1970 with correct log-diffs", {
  m <- read_monthly(monthly_path)
  X <- transform_monthly(m)
  expect_identical(names(X), c("date", "indpro", "payems", "rsafs", "unrate", "dgorder"))
  expect_true(min(X$date) >= as.Date("1970-02-01"))
  # spot-check one log-diff against a manual computation from the raw file
  i <- which(m$observation_date == as.Date("2026-04-01"))
  manual <- (log(m$INDPRO[i]) - log(m$INDPRO[i - 1])) * 100
  expect_equal(X$indpro[X$date == as.Date("2026-04-01")], manual)
  # unemployment is plain-differenced, not logged
  manual_u <- m$UNRATE[i] - m$UNRATE[i - 1]
  expect_equal(X$unrate[X$date == as.Date("2026-04-01")], manual_u)
})

test_that("nowcast_quarter is the first quarter after observed GDP, covered by monthly data", {
  gdp <- read_gdp(gdp_path)
  X <- transform_monthly(read_monthly(monthly_path))
  expect_identical(nowcast_quarter(gdp, X), "2026Q2")
  # and it fails loudly if monthly data does not reach into that quarter
  expect_error(nowcast_quarter(gdp, X[X$date < as.Date("2026-03-01"), ]))
})

test_that("ar_benchmark recovers a synthetic AR(2) and orders its quantiles", {
  set.seed(42)
  n <- 400
  y <- numeric(n)
  for (i in 3:n) y[i] <- 1 + 0.5 * y[i - 1] + 0.2 * y[i - 2] + rnorm(1, sd = 0.5)
  fc <- ar_benchmark(data.frame(gdp_saar = y), "2099Q1")
  expect_identical(fc$model_id, "konjecture_ar2")
  expect_identical(fc$target, "2099Q1")
  manual <- 1 + 0.5 * y[n] + 0.2 * y[n - 1]
  expect_true(abs(fc$point - manual) < 0.5)  # coefficients estimated, not assumed
  expect_true(all(diff(fc$q) > 0))
  expect_equal(fc$q[4], fc$point)  # median of a symmetric predictive density
})

test_that("dfm_bridge nowcasts the target quarter with ordered quantiles", {
  gdp <- read_gdp(gdp_path)
  X <- transform_monthly(read_monthly(monthly_path))
  fc <- dfm_bridge(X, gdp, "2026Q2")
  expect_identical(fc$model_id, "konjecture_dfm_bridge")
  expect_true(is.finite(fc$point))
  expect_true(all(diff(fc$q) > 0))
  expect_equal(fc$q[4], fc$point)
})

test_that("as_model_output emits hubverse-style point + quantile rows", {
  fc <- list(model_id = "m", target = "2026Q2", point = 2.5,
             q = 2.5 + qnorm(QUANTILES))
  out <- as_model_output(fc, "2026-07-06")
  expect_identical(nrow(out), 8L)
  expect_identical(sum(out$output_type == "point"), 1L)
  expect_identical(out$output_type_id[out$output_type == "quantile"], sprintf("%g", QUANTILES))
  expect_true(all(out$unit == "saar_pct" & out$declared_target == "advance"))
})

test_that("append_model_output is append-only with keyed dedupe", {
  fc <- list(model_id = "m", target = "2026Q2", point = 2.5, q = 2.5 + qnorm(QUANTILES))
  rows <- as_model_output(fc, "2026-07-06")
  path <- file.path(tempfile("mo"), "model_output.parquet")
  dir.create(dirname(path))
  append_model_output(rows, path)
  expect_identical(nrow(nanoparquet::read_parquet(path)), 8L)
  append_model_output(rows, path)  # same key -> no growth
  expect_identical(nrow(nanoparquet::read_parquet(path)), 8L)
  append_model_output(as_model_output(fc, "2026-07-07"), path)  # new run date -> appended
  expect_identical(nrow(nanoparquet::read_parquet(path)), 16L)
  expect_true(file.exists(sub("[.]parquet$", ".csv", path)))
})

test_that("render_dashboard degrades to the committed file when quarto is absent", {
  old_path <- Sys.getenv("PATH")
  on.exit(Sys.setenv(PATH = old_path))
  Sys.setenv(PATH = "")
  out <- file.path(root, "site/dashboard.html")
  expect_message(got <- render_dashboard("ignored.qmd", deps = NULL, output = out),
                 "quarto CLI not found")
  expect_identical(got, out)
})

test_that("render_dashboard renders the real dashboard when quarto is available", {
  skip_if(Sys.which("quarto") == "", "quarto CLI not installed")
  qmd <- file.path(root, "site/dashboard.qmd")
  out <- file.path(root, "site/dashboard.html")
  expect_identical(render_dashboard(qmd, deps = NULL, output = out), out)
  html <- readChar(out, file.size(out))
  expect_match(html, "Evolution of \\d{4}Q[1-4] US GDP nowcasts")
})

test_that("run_build_script executes a script and vouches for its outputs", {
  d <- tempfile("rbs")
  dir.create(d)
  script <- file.path(d, "ok.R")
  out <- file.path(d, "made.txt")
  writeLines(sprintf('writeLines("x", "%s")', out), script)
  expect_identical(run_build_script(script, deps = "ignored", outputs = out), out)
  bad <- file.path(d, "bad.R")
  writeLines("invisible(NULL)", bad)
  expect_error(run_build_script(bad, deps = NULL, outputs = file.path(d, "never.txt")))
})
