# X8: IMF WEO vintage ingestion. One WEO edition (April/October database) is
# one institutional forecast round: per country, years beyond the file's own
# "Estimates Start After" marker are forecasts, earlier years are history.
# The bulk files ship as UTF-16LE tab-separated text behind an .ashx/.xls name.

weo_read_lines <- function(path) {
  head <- readBin(path, "raw", n = 4L)
  enc <- if (length(head) >= 2L && head[1] == 0xFF && head[2] == 0xFE) "UTF-16LE"
         else if (length(head) >= 3L &&
                  identical(head[1:3], as.raw(c(0xEF, 0xBB, 0xBF)))) "UTF-8"
         # 2024-onward files are UTF-16LE with NO BOM: an ASCII-range header
         # reads as <char> 0x00 <char> 0x00
         else if (length(head) == 4L && head[2] == 0x00 && head[4] == 0x00 &&
                  head[1] != 0x00 && head[3] != 0x00) "UTF-16LE"
         # legacy (pre-2021) files are windows-1252: latin1 never truncates a
         # line the way an invalid byte under a UTF-8 read does, and every
         # field this package consumes is ASCII
         else "latin1"
  con <- file(path, encoding = enc)
  on.exit(close(con))
  readLines(con, warn = FALSE)
}

weo_table <- function(lines) {
  fields <- strsplit(lines, "\t", fixed = TRUE)
  hdr <- fields[[1]]
  body <- fields[-1]
  body <- body[vapply(body, length, 0L) == length(hdr)]  # drops footer/blank lines
  dt <- as.data.table(do.call(rbind, body))
  setnames(dt, hdr)
  named <- which(nzchar(trimws(hdr)))  # some editions carry a trailing tab
  dt[, named, with = FALSE]
}

weo_subset <- function(dt, subject = "NGDP_RPCH") {
  dt[dt[["WEO Subject Code"]] == subject]
}

# archive forecast rows for one edition; `regions` maps WEO ISO codes to the
# archive's region labels (extend for X4 without re-downloading)
weo_forecast_rows <- function(dt, year, month, regions = c(USA = "US")) {
  stopifnot(month %in% c(4L, 10L))
  yr_cols <- grep("^\\d{4}$", names(dt), value = TRUE)
  d <- dt[dt$ISO %in% names(regions)]
  long <- melt(d[, c("ISO", "Estimates Start After", yr_cols), with = FALSE],
               id.vars = c("ISO", "Estimates Start After"),
               variable.name = "target_period", value.name = "raw",
               variable.factor = FALSE)
  long[, value := suppressWarnings(as.numeric(gsub(",", "", raw, fixed = TRUE)))]
  long <- long[!is.na(value) &
                 as.integer(target_period) > as.integer(`Estimates Start After`)]
  data.table(
    source = "imf_weo", region = unname(regions[long$ISO]),
    variable = "rgdp_growth",
    target_period = long$target_period,
    # WEO databases go out mid-April / mid-October; exact day varies by year,
    # approximated as the 15th (same convention as the Philly SPF rounds)
    forecast_date = as.Date(sprintf("%d-%02d-15", year, month)),
    output_type = "point", output_id = NA_character_,
    value_native = long$value,
    unit_native = "yoy_pct",  # calendar-year average growth, same convention
    declared_target = "unspecified",  # as spf_ecb annual targets
    retrieved_at = NA_character_, source_file = NA_character_
  )[order(region, target_period)]
}
