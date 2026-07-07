# X2 scoring: vintage-correct scores against named target rules, stratified by
# horizon bucket (nowcast vs longer-term performance is never pooled — owner
# requirement recorded with the D1/D2 sign-off, docs/schema.md).
#
# Point forecasts today (institutional tracks): absolute/squared/signed error via
# scoringutils::score() when available (R3 "adopt"), with a dependency-light
# fallback computing the identical metrics. Quantile forecasts (own models) plug
# into the same structure once outcomes for their target quarters exist.

# quarters between the forecast date's quarter and the target quarter
quarters_ahead <- function(forecast_date, target_period) {
  fy <- as.integer(format(forecast_date, "%Y"))
  fq <- (as.integer(format(forecast_date, "%m")) - 1L) %/% 3L
  ty <- as.integer(substr(target_period, 1, 4))
  tq <- as.integer(substr(target_period, 6, 6)) - 1L
  (ty * 4L + tq) - (fy * 4L + fq)
}

horizon_bucket <- function(qa) {
  cut(qa, breaks = c(-Inf, -1, 0, 1, 4, Inf),
      labels = c("backcast", "nowcast", "1q_ahead", "2-4q_ahead", "5q+_ahead"))
}

# forecast rows scoreable against any rule:
#  - nyfed_retro rows are retrospective reconstructions: their forecast_date
#    predates the outcome publication, so they would masquerade as real-time —
#    excluded from scoring by construction
#  - ECB SPF rolling-quarter targets ("2026Q4") are yoy — scored vs yoy outcomes
#  - calendar-year / month-labelled ECB targets are not quarter-scoreable here
scoreable_forecasts <- function(fc) {
  f <- fc[source != "nyfed_retro",
          .(source, region, variable, target_period, forecast_date,
            predicted = value_native, unit_native)]
  f[source == "spf_ecb" & grepl("^\\d{4}Q[1-4]$", target_period),
    variable := "rgdp_growth_yoy"]
  f[grepl("^\\d{4}Q[1-4]$", target_period)]
}

# join forecasts to a truth table, enforce vintage correctness (forecast
# predates the scored outcome's publication) and unit match, add score columns
score_against <- function(f, truth, rule) {
  s <- truth[f, on = .(region, variable, target_period), nomatch = NULL]
  s <- s[forecast_date < published_on & unit_native == outcome_unit]
  s[, `:=`(quarters_ahead = quarters_ahead(forecast_date, target_period),
           horizon = horizon_bucket(quarters_ahead(forecast_date, target_period)),
           target_rule = rule)]
  s[, c("error", "abs_error", "sq_error") :=
      .(predicted - observed, abs(predicted - observed), (predicted - observed)^2)]
  s[order(source, region, target_period, forecast_date)]
}

score_first_release <- function(fc, oc) {
  truth <- oc[release_label == "first_release" | release_label == "advance",
              .(region, variable, target_period, published_on, observed = value_native,
                outcome_unit = unit_native)]
  s <- score_against(scoreable_forecasts(fc), truth, "first_release")
  if (requireNamespace("scoringutils", quietly = TRUE)) {
    su <- scoringutils::score(scoringutils::as_forecast_point(
      s[, .(model = source, region, variable, target_period, forecast_date,
            predicted, observed)]))
    # cross-check (order-independent), not trust
    stopifnot(isTRUE(all.equal(sort(su$ae_point), sort(s$abs_error))))
  }
  s
}

# last calendar day of a quarter label like "2020Q1"
quarter_end <- function(target_period) {
  y <- as.integer(substr(target_period, 1, 4))
  m <- as.integer(substr(target_period, 6, 6)) * 3L
  as.Date(sprintf("%d-%02d-01", y + m %/% 12L, m %% 12L + 1L)) - 1L
}

# shift a quarter label by k quarters
shift_quarter <- function(target_period, k) {
  y <- as.integer(substr(target_period, 1, 4))
  q <- as.integer(substr(target_period, 6, 6)) - 1L
  i <- y * 4L + q + as.integer(k)
  sprintf("%dQ%d", i %/% 4L, i %% 4L + 1L)
}

# X2/D2 fixed-horizon rule: score against the outcome as recorded k quarters
# after the target quarter's end — the last vintage published on or before the
# settle-by date. Targets whose settle-by date lies beyond the archive's as-of
# date (max published_on) are not yet settled and yield no score: D4 requires
# those cells blank-and-labelled, never filled with a premature vintage.
# US outcomes currently carry only the 'advance' label (no vintage_* rows until
# ALFRED, owner action O3), so US rows drop out by construction.
score_fixed_h <- function(fc, oc, k = 8) {
  v <- oc[grepl("^vintage_", release_label),
          .(region, variable, target_period, published_on,
            observed = value_native, outcome_unit = unit_native)]
  if (!nrow(v)) return(score_against(scoreable_forecasts(fc)[0], v, sprintf("fixed_h%d", k)))
  as_of <- max(v$published_on)
  v[, settle_by := quarter_end(shift_quarter(target_period, k))]
  v <- v[settle_by <= as_of & published_on <= settle_by]
  truth <- v[order(published_on),
             .SD[.N, .(published_on, observed, outcome_unit)],
             by = .(region, variable, target_period)]
  score_against(scoreable_forecasts(fc), truth, sprintf("fixed_h%d", k))
}

# aggregate per (source, region, variable, rule, horizon) — never across regions
score_summary <- function(scores) {
  scores[, .(n = .N,
             n_quarters = uniqueN(target_period),
             mae = round(mean(abs_error), 4),
             bias = round(mean(error), 4),
             rmse = round(sqrt(mean(sq_error)), 4)),
         by = .(source, region, variable, target_rule, horizon)][
           order(region, source, horizon)]
}

write_scores <- function(scores, summary, dir) {
  nanoparquet::write_parquet(scores, file.path(dir, "scores.parquet"))
  write.csv(scores, file.path(dir, "scores.csv"), row.names = FALSE)
  nanoparquet::write_parquet(summary, file.path(dir, "scores_summary.parquet"))
  write.csv(summary, file.path(dir, "scores_summary.csv"), row.names = FALSE)
  file.path(dir, c("scores.parquet", "scores_summary.parquet",
                   "scores.csv", "scores_summary.csv"))
}
