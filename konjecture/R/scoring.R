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

# forecast rows scoreable against a rule: matching outcome exists and the
# forecast predates that outcome's publication (vintage correctness)
score_first_release <- function(fc, oc) {
  truth <- oc[release_label == "first_release" | release_label == "advance",
              .(region, variable, target_period, published_on, observed = value_native,
                outcome_unit = unit_native)]
  # nyfed_retro rows are retrospective reconstructions: their forecast_date
  # predates the outcome publication, so they would masquerade as real-time —
  # excluded from scoring by construction
  fc <- fc[source != "nyfed_retro"]
  # ECB SPF rolling-quarter targets ("2026Q4") are yoy — score vs the yoy outcome
  f <- fc[, .(source, region, variable, target_period, forecast_date,
              predicted = value_native, unit_native)]
  f[source == "spf_ecb" & grepl("^\\d{4}Q[1-4]$", target_period),
    variable := "rgdp_growth_yoy"]
  # calendar-year / month-labelled ECB targets are not quarter-scoreable here
  f <- f[grepl("^\\d{4}Q[1-4]$", target_period)]
  s <- truth[f, on = .(region, variable, target_period), nomatch = NULL]
  s <- s[forecast_date < published_on & unit_native == outcome_unit]
  s[, `:=`(quarters_ahead = quarters_ahead(forecast_date, target_period),
           horizon = horizon_bucket(quarters_ahead(forecast_date, target_period)),
           target_rule = "first_release")]
  s[, c("error", "abs_error", "sq_error") :=
      .(predicted - observed, abs(predicted - observed), (predicted - observed)^2)]
  if (requireNamespace("scoringutils", quietly = TRUE)) {
    su <- scoringutils::score(scoringutils::as_forecast_point(
      s[, .(model = source, region, variable, target_period, forecast_date,
            predicted, observed)]))
    # cross-check (order-independent), not trust
    stopifnot(isTRUE(all.equal(sort(su$ae_point), sort(s$abs_error))))
  }
  s[order(source, region, target_period, forecast_date)]
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
