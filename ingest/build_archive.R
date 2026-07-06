#!/usr/bin/env Rscript
# Build the normalized vintage-correct archive from data/raw/ (see docs/schema.md).
#
# Reads only the local cache — no network. Emits data/archive/{forecasts,outcomes}
# as parquet + csv mirror, append-only semantics: the build is deterministic from
# the raw cache, so "appending" happens by refreshing the cache, not by editing
# outputs. Every row carries provenance (source_file, retrieved_at).

suppressMessages(library(data.table))

ROOT <- normalizePath(file.path(dirname(sub("--file=", "", grep("--file=", commandArgs(FALSE), value = TRUE))), ".."))
RAW <- file.path(ROOT, "data", "raw")
OUT <- file.path(ROOT, "data", "archive")

MANIFEST <- jsonlite::read_json(file.path(RAW, "manifest.json"))
retrieved <- function(fname) MANIFEST[[fname]]$retrieved_at

saar_to_qq <- function(s) ((1 + s / 100)^0.25 - 1) * 100

quarter_label <- function(d) {
  d <- as.Date(d)
  sprintf("%dQ%d", as.integer(format(d, "%Y")), (as.integer(format(d, "%m")) - 1) %/% 3 + 1)
}

# --- GDPNow: forecasts (TrackingDeepArchives + TrackingArchives) + outcomes (TrackRecord) ---

gdpnow <- function() {
  f <- "gdpnow_tracking.xlsx"
  path <- file.path(RAW, f)
  frames <- lapply(c("TrackingDeepArchives", "TrackingArchives"), function(sheet) {
    df <- suppressWarnings(readxl::read_excel(path, sheet = sheet))
    names(df) <- trimws(names(df))
    keep <- as.data.table(df[, c("Forecast Date", "Quarter being forecasted", "GDP Nowcast")])
    setnames(keep, c("fdate", "qdate", "value"))
    keep <- keep[!is.na(fdate) & !is.na(qdate) & !is.na(value)]
    keep[, sheet := sheet]
    keep
  })
  fc <- rbindlist(frames)
  # overlap between the two tabs: same behavior as the validated Python build —
  # rows sorted by sheet name, last kept per (forecast date, quarter)
  setorder(fc, sheet)
  fc <- fc[!duplicated(fc, by = c("fdate", "qdate"), fromLast = TRUE)]
  forecasts <- data.table(
    source = "gdpnow", region = "US", variable = "rgdp_growth",
    target_period = quarter_label(fc$qdate),
    forecast_date = as.Date(fc$fdate),
    output_type = "point", output_id = NA_character_,
    value_native = as.numeric(fc$value), unit_native = "saar_pct",
    declared_target = "advance",  # GDPNow TrackRecord scores itself vs BEA advance
    retrieved_at = retrieved(f), source_file = f
  )

  tr <- suppressWarnings(readxl::read_excel(path, sheet = "TrackRecord", skip = 1, col_names = FALSE))
  tr <- as.data.table(tr[, c(1, 3, 4)])
  setnames(tr, c("qdate", "value", "pub"))
  tr <- tr[!is.na(qdate) & !is.na(value) & !is.na(pub)]
  outcomes <- data.table(
    region = "US", variable = "rgdp_growth",
    target_period = quarter_label(tr$qdate),
    release_label = "advance",
    published_on = as.Date(tr$pub),
    value_native = as.numeric(tr$value), unit_native = "saar_pct",
    source = "gdpnow_trackrecord(BEA)",
    retrieved_at = retrieved(f), source_file = f
  )
  list(fc = forecasts, oc = outcomes)
}

gdpnow_current <- function() {
  # In-flight quarter from CurrentQtrEvolution (not yet in the archive tabs):
  # [Date, Major Releases, GDP*] column triplets; quarter parsed from the
  # 'Initial GDPNow YY:Qq forecast' label.
  f <- "gdpnow_tracking.xlsx"
  df <- suppressWarnings(readxl::read_excel(file.path(RAW, f), sheet = "CurrentQtrEvolution",
                                            col_names = FALSE, col_types = "text"))
  cells <- unlist(df, use.names = FALSE)
  m <- regmatches(cells, regexec("Initial GDPNow (\\d\\d):Q(\\d) forecast", cells))
  m <- Filter(function(x) length(x) == 3, m)
  if (!length(m)) return(data.table())
  tp <- sprintf("20%sQ%s", m[[1]][2], m[[1]][3])
  rows <- rbindlist(lapply(seq(1, ncol(df) - 2, by = 3), function(c0) {
    d <- suppressWarnings(as.Date(as.numeric(df[[c0]]), origin = "1899-12-30"))
    v <- suppressWarnings(as.numeric(df[[c0 + 2]]))
    ok <- !is.na(d) & !is.na(v)
    data.table(forecast_date = d[ok], value = v[ok])
  }))
  rows <- rows[!duplicated(forecast_date)]
  data.table(
    source = "gdpnow", region = "US", variable = "rgdp_growth",
    target_period = tp, forecast_date = rows$forecast_date,
    output_type = "point", output_id = NA_character_,
    value_native = rows$value, unit_native = "saar_pct",
    declared_target = "advance",
    retrieved_at = retrieved(f), source_file = paste0(f, ":CurrentQtrEvolution")
  )
}

# --- NY Fed Staff Nowcast: Forecasts By Quarter grid (2023- relaunch file) ---

nyfed <- function() {
  f <- "nyfed_staff_nowcast.xlsx"
  raw <- suppressWarnings(readxl::read_excel(file.path(RAW, f), sheet = "Forecasts By Quarter",
                                             col_names = FALSE, col_types = "text"))
  hdr_row <- which(trimws(raw[[1]]) == "Forecast Date")[1]
  hdr <- unlist(raw[hdr_row, ], use.names = FALSE)
  body <- raw[-seq_len(hdr_row), , drop = FALSE]
  names(body) <- ifelse(is.na(hdr), paste0("x", seq_along(hdr)), hdr)
  dt <- as.data.table(body)
  dt[, fdate := as.Date(as.numeric(`Forecast Date`), origin = "1899-12-30")]
  dt <- dt[!is.na(fdate)]
  qcols <- grep("^\\d{4}Q[1-4]$", names(dt), value = TRUE)
  long <- melt(dt, id.vars = "fdate", measure.vars = qcols,
               variable.name = "target_period", value.name = "value", variable.factor = FALSE)
  long[, value := suppressWarnings(as.numeric(value))]
  long <- long[!is.na(value)]
  data.table(
    source = "nyfed", region = "US", variable = "rgdp_growth",
    target_period = long$target_period, forecast_date = long$fdate,
    output_type = "point", output_id = NA_character_,
    value_native = long$value, unit_native = "saar_pct",
    declared_target = "unspecified",
    retrieved_at = retrieved(f), source_file = f
  )
}

# --- Philadelphia Fed SPF: mean current-quarter growth (drgdp2) per survey round ---

PHILLY_ROUND_MONTH <- c(2, 5, 8, 11)  # survey published mid Feb/May/Aug/Nov

spf_philly <- function() {
  f <- "spf_philly_meangrowth.xlsx"
  df <- as.data.table(readxl::read_excel(file.path(RAW, f), sheet = "RGDP"))
  df <- df[!is.na(drgdp2)]
  # drgdp2 = mean forecast for the survey's own quarter (the SPF "nowcast"), SAAR %.
  # Exact deadline dates aren't in this file: forecast_date is approximated as the
  # 15th of the round's middle month (documented in ingest/README.md).
  data.table(
    source = "spf_philly", region = "US", variable = "rgdp_growth",
    target_period = sprintf("%dQ%d", as.integer(df$YEAR), as.integer(df$QUARTER)),
    forecast_date = as.Date(sprintf("%d-%02d-15", as.integer(df$YEAR),
                                    PHILLY_ROUND_MONTH[as.integer(df$QUARTER)])),
    output_type = "point", output_id = NA_character_,
    value_native = as.numeric(df$drgdp2), unit_native = "saar_pct",
    declared_target = "unspecified",
    retrieved_at = retrieved(f), source_file = f
  )
}

# --- ECB SPF: mean GDP point forecast per round & target (year-on-year, kept native) ---

GDP_HDR <- "GROWTH EXPECTATIONS"

spf_ecb <- function() {
  f <- "spf_ecb_individual.zip"
  zpath <- file.path(RAW, f)
  entries <- sort(grep("^\\d{4}Q[1-4]\\.csv$", utils::unzip(zpath, list = TRUE)$Name, value = TRUE))
  out <- lapply(entries, function(name) {
    yr <- as.integer(substr(name, 1, 4)); qn <- as.integer(substr(name, 6, 6))
    lines <- readLines(unz(zpath, name), warn = FALSE)
    fields <- strsplit(lines, ",", fixed = TRUE)
    col0 <- vapply(fields, function(x) if (length(x)) x[1] else "", "")
    # section headers = prose rows (letters, not TARGET_PERIOD); data rows start
    # with a target period like "2026", "2026Q4", "2027Mar"
    is_hdr <- grepl("[A-Za-z]", col0) & col0 != "TARGET_PERIOD" &
      !grepl("^\\d{4}(Q[1-4]|[A-Z][a-z]{2})?$", col0)
    hdr_idx <- which(is_hdr)
    gdp_start <- hdr_idx[grepl(GDP_HDR, col0[hdr_idx], fixed = TRUE)]
    if (!length(gdp_start)) return(NULL)
    start <- gdp_start[1]
    later <- hdr_idx[hdr_idx > start]
    end <- if (length(later)) later[1] else length(lines) + 1L
    sec <- seq(start + 1L, end - 1L)
    trow <- sec[col0[sec] == "TARGET_PERIOD"][1]
    if (is.na(trow)) return(NULL)
    point_col <- which(fields[[trow]] == "POINT")[1]
    body <- sec[sec > trow & col0[sec] != ""]
    vals <- suppressWarnings(as.numeric(vapply(fields[body], function(x)
      if (length(x) >= point_col) x[point_col] else NA_character_, "")))
    grp <- data.table(target = col0[body], point = vals)[!is.na(point)]
    if (!nrow(grp)) return(NULL)
    agg <- grp[, .(value = round(mean(point), 4)), keyby = target]
    data.table(
      source = "spf_ecb", region = "EA", variable = "rgdp_growth",
      target_period = agg$target,
      # ECB SPF rounds close in the first month of the quarter (approx: 15th)
      forecast_date = as.Date(sprintf("%d-%02d-15", yr, (qn - 1L) * 3L + 1L)),
      output_type = "point", output_id = NA_character_,
      value_native = agg$value, unit_native = "yoy_pct",
      declared_target = "unspecified",
      retrieved_at = retrieved(f), source_file = paste0(f, ":", name)
    )
  })
  rbindlist(Filter(Negate(is.null), out))
}

# --- assemble ---

main <- function() {
  dir.create(OUT, recursive = TRUE, showWarnings = FALSE)
  gd <- gdpnow()
  gd_fc <- gd$fc
  gd_cur <- gdpnow_current()
  if (nrow(gd_cur)) {
    gd_fc <- rbind(gd_fc, gd_cur)
    gd_fc <- gd_fc[!duplicated(gd_fc, by = c("target_period", "forecast_date"))]
  }
  forecasts <- rbindlist(list(gd_fc, nyfed(), spf_philly(), spf_ecb()))
  forecasts[, value_qq := ifelse(unit_native == "saar_pct",
                                 round(saar_to_qq(value_native), 4), NA_real_)]
  outcomes <- gd$oc
  outcomes[, value_qq := round(saar_to_qq(value_native), 4)]

  setcolorder(forecasts, c("source", "region", "variable", "target_period", "forecast_date",
                           "output_type", "output_id", "value_native", "unit_native", "value_qq",
                           "declared_target", "retrieved_at", "source_file"))
  setcolorder(outcomes, c("region", "variable", "target_period", "release_label", "published_on",
                          "value_native", "unit_native", "value_qq", "source", "retrieved_at",
                          "source_file"))
  setorder(forecasts, source, target_period, forecast_date)
  setorder(outcomes, target_period)

  for (name in c("forecasts", "outcomes")) {
    df <- get(name)
    nanoparquet::write_parquet(df, file.path(OUT, paste0(name, ".parquet")))
    fwrite(df, file.path(OUT, paste0(name, ".csv")))
    cat(sprintf("%s: %s rows -> data/archive/%s.parquet (+.csv)\n",
                name, format(nrow(df), big.mark = ","), name))
  }
  cat("\nforecast rows per source:\n")
  print(forecasts[, .(rows = .N, first = min(forecast_date), last = max(forecast_date)), by = source])
}

main()
