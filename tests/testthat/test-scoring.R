# konjecture/R/scoring.R — X2 scoring: horizon buckets, vintage correctness,
# and hand-checked score values against the real archive.

root <- Sys.getenv("KONJ_ROOT")

load_tables <- function() {
  list(fc = as.data.table(nanoparquet::read_parquet(file.path(root, "data/archive/forecasts.parquet"))),
       oc = as.data.table(nanoparquet::read_parquet(file.path(root, "data/archive/outcomes.parquet"))))
}

test_that("quarters_ahead and horizon_bucket implement the schema definition", {
  expect_identical(quarters_ahead(as.Date("2026-05-15"), "2026Q2"), 0L)   # inside quarter
  expect_identical(quarters_ahead(as.Date("2026-07-01"), "2026Q2"), -1L)  # after quarter end
  expect_identical(quarters_ahead(as.Date("2025-01-15"), "2026Q4"), 7L)
  expect_identical(as.character(horizon_bucket(c(-1L, 0L, 1L, 3L, 7L))),
                   c("backcast", "nowcast", "1q_ahead", "2-4q_ahead", "5q+_ahead"))
})

test_that("score_first_release is vintage-correct and excludes retro rows", {
  tb <- load_tables()
  s <- score_first_release(tb$fc, tb$oc)
  expect_false("nyfed_retro" %in% s$source)
  # every scored forecast predates the outcome it is scored against
  expect_true(all(s$forecast_date < s$published_on))
  # hand-checked: GDPNow final 2026Q1 nowcast 1.239175 vs advance 1.9901
  g <- s[source == "gdpnow" & target_period == "2026Q1"][order(forecast_date)][.N]
  expect_equal(g$error, -0.750925, tolerance = 1e-5)
  expect_identical(as.character(g$horizon), "backcast")  # made 2026-04-29, Q1 ended in March
  # ECB SPF rolling-quarter targets are scored against the yoy outcome
  e <- s[source == "spf_ecb"]
  expect_identical(unique(e$variable), "rgdp_growth_yoy")
  expect_true(all(as.character(e$horizon) %in% c("2-4q_ahead", "5q+_ahead")))
})

test_that("score_summary aggregates per source x region x horizon, never across", {
  tb <- load_tables()
  s <- score_first_release(tb$fc, tb$oc)
  agg <- score_summary(s)
  expect_identical(nrow(agg[duplicated(agg[, .(source, region, variable, target_rule, horizon)])]), 0L)
  # recompute one cell by hand: GDPNow backcast MAE
  gb <- s[source == "gdpnow" & horizon == "backcast"]
  expect_equal(agg[source == "gdpnow" & horizon == "backcast", mae], round(mean(gb$abs_error), 4))
  expect_equal(agg[source == "gdpnow" & horizon == "backcast", n], nrow(gb))
  # no cross-region rows by construction
  expect_true(all(agg[region == "EA", source] == "spf_ecb"))
})

test_that("write_scores emits parquet + csv mirrors", {
  tb <- load_tables()
  s <- score_first_release(tb$fc, tb$oc)[1:20]
  d <- tempfile("scores")
  dir.create(d)
  out <- write_scores(s, score_summary(s), d)
  expect_true(all(file.exists(out)))
  expect_identical(nrow(nanoparquet::read_parquet(file.path(d, "scores.parquet"))), 20L)
})
