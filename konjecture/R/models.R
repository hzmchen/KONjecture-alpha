# X3: model-adapter interface. Every model class enters the pipeline through
# one contract — adapter(data, target_q) -> list(model_id, target, point, q) —
# so new model classes plug in without touching the pipeline wiring. `data` is
# whatever the usage layer assembled (here: list(gdp = ..., X = ...)); adapters
# pick the pieces they need.

validate_forecast <- function(fc) {
  fail <- function(what) stop("forecast violates the adapter contract: ", what,
                              call. = FALSE)
  if (!is.list(fc)) fail("not a list")
  if (!is.character(fc$model_id) || length(fc$model_id) != 1L || !nzchar(fc$model_id))
    fail("model_id must be a non-empty character scalar")
  if (!is.character(fc$target) || length(fc$target) != 1L ||
      !grepl("^\\d{4}Q[1-4]$", fc$target))
    fail("target must be a single YYYYQn quarter label")
  if (!is.numeric(fc$point) || length(fc$point) != 1L || !is.finite(fc$point))
    fail("point must be a single finite number")
  if (!is.numeric(fc$q) || length(fc$q) != length(QUANTILES) ||
      !all(is.finite(fc$q)) || is.unsorted(fc$q))
    fail(sprintf("q must be %d finite non-decreasing values (one per QUANTILES)",
                 length(QUANTILES)))
  fc
}

# registry: one named adapter per model class; midasr-backed class appears only
# when the package is installed (mirrors dfms/midasr living in Suggests)
model_adapters <- function() {
  adapters <- list(
    konjecture_ar2 = function(data, target_q) ar_benchmark(data$gdp, target_q),
    konjecture_dfm_bridge = function(data, target_q) dfm_bridge(data$X, data$gdp, target_q)
  )
  if (requireNamespace("midasr", quietly = TRUE))
    adapters$konjecture_midas_bridge <-
      function(data, target_q) midas_bridge(data$X, data$gdp, target_q)
  adapters
}

run_adapters <- function(adapters, data, target_q) {
  Map(function(nm, adapter) {
    fc <- tryCatch(validate_forecast(adapter(data, target_q)),
                   error = function(e) stop("adapter '", nm, "': ",
                                            conditionMessage(e), call. = FALSE))
    if (!identical(fc$target, target_q))
      stop("adapter '", nm, "' returned target ", fc$target,
           " instead of ", target_q, call. = FALSE)
    fc
  }, names(adapters), adapters)
}

# --- MIDAS bridge: monthly indicator regressed on quarterly GDP growth at
# mixed frequency (restricted lag polynomial), one-quarter-ahead nowcast ---
midas_bridge <- function(X, gdp, target_q, x_var = "indpro", hf_lags = 0:8) {
  qs <- month_quarter(X$date)
  # months of the target quarter observed so far (calendar rows can exist with
  # NA values before release), padded to 3 with their mean — the same
  # partial-quarter disclosure as dfm_bridge's within-quarter factor mean
  x_target <- X[[x_var]][qs == target_q]
  x_target <- x_target[is.finite(x_target)]
  stopifnot("no observed target-quarter months" = length(x_target) >= 1L)
  x_target <- c(x_target, rep(mean(x_target), 3L - length(x_target)))

  # history: complete 3-month quarters that also have observed GDP
  hist <- X[qs != target_q, ]
  hq <- month_quarter(hist$date)
  complete <- names(which(table(hq) == 3L))
  keep <- hq %in% complete & hq %in% gdp$quarter
  hist <- hist[keep, ][order(hist$date[keep]), ]
  y_quarters <- sort(unique(month_quarter(hist$date)))
  y <- gdp$gdp_saar[match(y_quarters, gdp$quarter)]
  x <- hist[[x_var]]

  # midasr resolves mls/nealmon by bare name in the formula; bind them locally
  # (the formula environment) instead of importing the Suggests-only package
  mls <- midasr::mls
  nealmon <- midasr::nealmon
  fit <- midasr::midas_r(y ~ mls(y, 1, 1) + mls(x, hf_lags, 3, nealmon),
                         start = list(x = c(1, -0.5)))
  cf <- coef(fit, midas = TRUE)  # intercept, y-lag, then expanded hf lag weights
  xa <- c(x, x_target)
  point <- unname(cf[1] + cf[2] * y[length(y)] +
                    sum(cf[-(1:2)] * xa[length(xa) - hf_lags]))
  r <- residuals(fit)
  sigma <- sqrt(sum(r^2) / (length(r) - length(coef(fit))))
  list(model_id = "konjecture_midas_bridge", target = target_q, point = point,
       q = point + qnorm(QUANTILES) * sigma)
}
