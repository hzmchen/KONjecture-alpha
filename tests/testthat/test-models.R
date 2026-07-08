# X3: model-adapter interface (konjecture/R/models.R). Every model class enters
# the pipeline through one contract: adapter(data, target_q) -> forecast list
# (model_id, target, point, q over QUANTILES), so new model classes plug in
# without touching the pipeline wiring.

root <- Sys.getenv("KONJ_ROOT")
monthly_path <- file.path(root, "data/raw/fred_monthly_indicators.csv")
gdp_path <- file.path(root, "data/raw/fred_gdp_growth.csv")

ok_fc <- list(model_id = "m", target = "2026Q2", point = 2.5,
              q = 2.5 + qnorm(QUANTILES))

test_that("validate_forecast accepts a conforming forecast and returns it", {
  expect_identical(validate_forecast(ok_fc), ok_fc)
})

test_that("validate_forecast rejects each contract violation with a named reason", {
  expect_error(validate_forecast(ok_fc[-1]), "model_id")
  expect_error(validate_forecast(modifyList(ok_fc, list(target = "2026-Q2"))), "target")
  expect_error(validate_forecast(modifyList(ok_fc, list(point = c(1, 2)))), "point")
  expect_error(validate_forecast(modifyList(ok_fc, list(point = NA_real_))), "point")
  expect_error(validate_forecast(modifyList(ok_fc, list(q = 1:3))), "q")
  expect_error(validate_forecast(modifyList(ok_fc, list(q = rev(ok_fc$q)))), "q")
  expect_error(validate_forecast(unclass(as.data.frame(ok_fc[1:3]))), "q")
})

test_that("model_adapters exposes the existing model classes behind one signature", {
  ad <- model_adapters()
  expect_true(all(c("konjecture_ar2", "konjecture_dfm_bridge") %in% names(ad)))
  for (f in ad) expect_identical(names(formals(f)), c("data", "target_q"))
})

test_that("the existing models run through the interface and self-report their ids", {
  gdp <- read_gdp(gdp_path)
  X <- transform_monthly(read_monthly(monthly_path))
  data <- list(gdp = gdp, X = X)
  target_q <- nowcast_quarter(gdp, X)
  fcs <- run_adapters(model_adapters()[c("konjecture_ar2", "konjecture_dfm_bridge")],
                      data, target_q)
  expect_identical(names(fcs), c("konjecture_ar2", "konjecture_dfm_bridge"))
  for (nm in names(fcs)) {
    expect_identical(fcs[[nm]]$model_id, nm)
    expect_identical(fcs[[nm]]$target, target_q)
    expect_true(is.finite(fcs[[nm]]$point))
    expect_true(all(diff(fcs[[nm]]$q) > 0))
  }
  # and the adapter results feed the existing hubverse writer unchanged
  out <- do.call(rbind, lapply(fcs, as_model_output, run_date = "2026-07-08"))
  expect_identical(nrow(out), 16L)
})

test_that("run_adapters rejects an adapter whose output breaks the contract", {
  broken <- function(data, target_q) list(model_id = "x", target = target_q,
                                          point = 1, q = 1:3)
  expect_error(run_adapters(list(broken = broken), list(), "2026Q2"), "broken")
  # an adapter that mislabels its target is caught too
  liar <- function(data, target_q) modifyList(ok_fc, list(target = "1999Q1"))
  expect_error(run_adapters(list(liar = liar), list(), "2026Q2"), "target")
})

test_that("midas_bridge nowcasts the target quarter through the same contract", {
  skip_if_not_installed("midasr")
  gdp <- read_gdp(gdp_path)
  X <- transform_monthly(read_monthly(monthly_path))
  target_q <- nowcast_quarter(gdp, X)
  fc <- midas_bridge(X, gdp, target_q)
  expect_identical(fc$model_id, "konjecture_midas_bridge")
  expect_identical(fc$target, target_q)
  expect_true(is.finite(fc$point))
  expect_true(all(diff(fc$q) > 0))
  expect_equal(fc$q[4], fc$point)
  # plausible magnitude for US quarterly SAAR growth, not an unscaled artifact
  expect_true(abs(fc$point) < 15)
  # and it registers as a third adapter when midasr is available
  expect_true("konjecture_midas_bridge" %in% names(model_adapters()))
})
