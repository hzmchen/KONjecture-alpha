# N2 spike functions: data prep, AR benchmark, DFM bridge nowcast, hubverse output.
# Deliberately thin (rebuild-with-AI glue per research/03 §5); the load-bearing
# science is dfms::DFM.

QUANTILES <- c(0.025, 0.1, 0.25, 0.5, 0.75, 0.9, 0.975)

read_monthly <- function(path) {
  df <- read.csv(path)
  df$observation_date <- as.Date(df$observation_date)
  df
}

read_gdp <- function(path) {
  df <- read.csv(path)
  names(df) <- c("date", "gdp_saar")
  df$date <- as.Date(df$date)
  df$quarter <- paste0(format(df$date, "%Y"), "Q", (as.integer(format(df$date, "%m")) - 1) %/% 3 + 1)
  df
}

# stationarize: log-diff for trending levels, diff for rates; drop early NA-heavy years
transform_monthly <- function(raw) {
  d <- raw[raw$observation_date >= as.Date("1970-01-01"), ]
  X <- data.frame(
    date    = d$observation_date,
    indpro  = c(NA, diff(log(d$INDPRO))) * 100,
    payems  = c(NA, diff(log(d$PAYEMS))) * 100,
    rsafs   = c(NA, diff(log(d$RSAFS))) * 100,
    unrate  = c(NA, diff(d$UNRATE)),
    dgorder = c(NA, diff(log(d$DGORDER))) * 100
  )
  X[-1, ]
}

month_quarter <- function(dates) {
  paste0(format(dates, "%Y"), "Q", (as.integer(format(dates, "%m")) - 1) %/% 3 + 1)
}

# quarter after the last one with observed GDP, provided monthly data reaches into it
nowcast_quarter <- function(gdp, X) {
  last_gdp <- max(gdp$date)
  nxt <- seq(last_gdp, by = "3 months", length.out = 2)[2]
  q <- month_quarter(nxt)
  stopifnot(any(month_quarter(X$date) == q))
  q
}

# --- AR(2) benchmark with normal predictive quantiles ---
ar_benchmark <- function(gdp, target_q) {
  y <- gdp$gdp_saar
  n <- length(y)
  fit <- lm(y[3:n] ~ y[2:(n - 1)] + y[1:(n - 2)])
  sigma <- summary(fit)$sigma
  b <- coef(fit)
  point <- unname(b[1] + b[2] * y[n] + b[3] * y[n - 1])
  list(model_id = "konjecture_ar2", target = target_q, point = point,
       q = point + qnorm(QUANTILES) * sigma)
}

# --- DFM bridge: monthly factor -> quarterly mean -> OLS bridge to GDP growth ---
dfm_bridge <- function(X, gdp, target_q, r = 2, p = 2) {
  xm <- as.matrix(X[, -1])
  rownames(xm) <- as.character(X$date)
  m <- dfms::DFM(xm, r = r, p = p)
  f <- data.frame(quarter = month_quarter(X$date), f1 = m$F_qml[, 1])
  fq <- aggregate(f1 ~ quarter, f, mean)

  dat <- merge(gdp[, c("quarter", "gdp_saar")], fq, by = "quarter")
  dat <- dat[order(dat$quarter), ]
  n <- nrow(dat)
  fit <- lm(dat$gdp_saar[2:n] ~ dat$f1[2:n] + dat$gdp_saar[1:(n - 1)])
  sigma <- summary(fit)$sigma
  b <- coef(fit)
  f_target <- fq$f1[fq$quarter == target_q]  # mean over the months available so far
  point <- unname(b[1] + b[2] * f_target + b[3] * dat$gdp_saar[n])
  list(model_id = "konjecture_dfm_bridge", target = target_q, point = point,
       q = point + qnorm(QUANTILES) * sigma)
}

# --- hubverse-style model_output rows (units: SAAR %, declared target: advance) ---
as_model_output <- function(fc, run_date) {
  rbind(
    data.frame(model_id = fc$model_id, forecast_date = run_date,
               region = "US", variable = "rgdp_growth", unit = "saar_pct",
               target_period = fc$target, output_type = "point",
               output_type_id = NA_character_, value = round(fc$point, 4),
               declared_target = "advance"),
    data.frame(model_id = fc$model_id, forecast_date = run_date,
               region = "US", variable = "rgdp_growth", unit = "saar_pct",
               target_period = fc$target, output_type = "quantile",
               output_type_id = sprintf("%g", QUANTILES), value = round(fc$q, 4),
               declared_target = "advance")
  )
}

# append-only parquet archive: add rows whose key is not present yet
append_model_output <- function(rows, path) {
  key <- function(d) paste(d$model_id, d$forecast_date, d$target_period,
                           d$output_type, d$output_type_id, sep = "|")
  if (file.exists(path)) {
    old <- nanoparquet::read_parquet(path)
    rows <- rows[!(key(rows) %in% key(old)), ]
    rows <- rbind(old, rows)
  }
  nanoparquet::write_parquet(rows, path)
  write.csv(rows, sub("[.]parquet$", ".csv", path), row.names = FALSE)
  path
}
