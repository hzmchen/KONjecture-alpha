# build_archive.R — parsers run against the committed raw cache (deterministic
# fixtures); spot values are the hand-verified numbers from ingest/README.md.

root <- Sys.getenv("KONJ_ROOT")

test_that("saar_to_qq matches the documented conversion", {
  expect_equal(round(saar_to_qq(1.9901), 4), 0.4939)
  expect_equal(saar_to_qq(0), 0)
  expect_equal(round(saar_to_qq(c(4, -4)), 4), c(0.9853, -1.0154))
})

test_that("quarter_label maps quarter-end and quarter-start dates", {
  expect_identical(quarter_label(as.Date(c("2014-06-30", "2026-01-01", "1999-12-31"))),
                   c("2014Q2", "2026Q1", "1999Q4"))
})

test_that("gdpnow parses archive tabs and TrackRecord outcomes", {
  gd <- gdpnow()
  expect_identical(nrow(gd$fc), 2076L)
  expect_identical(nrow(gd$oc), 59L)
  # hand-verified vs the TrackRecord tab (see ingest/README.md)
  final_26q1 <- gd$fc[target_period == "2026Q1"][order(forecast_date)][.N]
  expect_equal(round(final_26q1$value_native, 4), 1.2392)
  o <- gd$oc[target_period == "2026Q1"]
  expect_equal(round(o$value_native, 4), 1.9901)
  expect_identical(o$published_on, as.Date("2026-04-30"))
  expect_identical(unique(gd$fc$declared_target), "advance")
})

test_that("gdpnow_current picks up the in-flight quarter", {
  cur <- gdpnow_current()
  expect_identical(unique(cur$target_period), "2026Q2")
  expect_identical(nrow(cur), 27L)
  first <- cur[order(forecast_date)][1]
  expect_identical(first$forecast_date, as.Date("2026-04-30"))
  expect_equal(round(first$value_native, 4), 3.7007)
})

test_that("nyfed melts the weekly grid", {
  ny <- nyfed()
  expect_identical(nrow(ny), 324L)
  expect_identical(max(ny$forecast_date), as.Date("2026-07-03"))
  expect_true(all(grepl("^\\d{4}Q[1-4]$", ny$target_period)))
})

test_that("spf_philly extracts the current-quarter mean per round", {
  ph <- spf_philly()
  expect_identical(nrow(ph), 231L)
  r <- ph[target_period == "2026Q2"]
  expect_equal(round(r$value_native, 4), 2.1484)
  expect_identical(r$forecast_date, as.Date("2026-05-15"))
})

test_that("spf_ecb section parsing survives its two known traps", {
  ecb <- spf_ecb()
  expect_identical(nrow(ecb), 627L)
  # trap 1: unemployment rows leaking through a bad section boundary (was 3.39)
  spot <- ecb[forecast_date == as.Date("2026-04-15") & target_period == "2026"]
  expect_equal(spot$value_native, 0.9556)
  # trap 2: the half-even rounding cell (exact mean 2.92225 -> 2.9222)
  cell <- ecb[forecast_date == as.Date("2000-07-15") & target_period == "2002"]
  expect_equal(cell$value_native, 2.9222)
  expect_true(all(ecb$unit_native == "yoy_pct"))
})

test_that("archive_main reproduces the committed archive exactly", {
  tmp <- tempfile("archout")
  res <- archive_main(out_dir = tmp)
  expect_identical(nrow(res$forecasts), 3285L)
  expect_true(all(is.na(res$forecasts[unit_native == "yoy_pct", value_qq])))
  for (name in c("forecasts", "outcomes")) {
    got <- fread(file.path(tmp, paste0(name, ".csv")))
    want <- fread(file.path(root, "data", "archive", paste0(name, ".csv")))
    expect_equal(got, want, ignore_attr = TRUE)
  }
})
