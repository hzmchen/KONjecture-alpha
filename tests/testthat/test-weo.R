# X8: IMF WEO vintage ingestion (konjecture/R/weo.R). Each WEO edition is one
# institutional forecast round: annual real GDP growth (NGDP_RPCH) rows whose
# year lies beyond the vintage's own "Estimates Start After" marker are
# forecasts; everything else is history and stays out of the forecasts table.

root <- Sys.getenv("KONJ_ROOT")

# synthetic decoded WEO bulk-file lines (tab-separated, the real column set)
weo_fixture_lines <- function() {
  hdr <- paste("WEO Country Code", "ISO", "WEO Subject Code", "Country",
               "Subject Descriptor", "Subject Notes", "Units", "Scale",
               "Country/Series-specific Notes",
               "2023", "2024", "2025", "2026", "2027",
               "Estimates Start After", sep = "\t")
  us_gdp <- paste("111", "USA", "NGDP_RPCH", "United States",
                  "Gross domestic product, constant prices", "note",
                  "Percent change", "Units", "cnote",
                  "2.9", "2.8", "1.8", "1.7", "2.0", "2024", sep = "\t")
  us_lvl <- paste("111", "USA", "NGDP_R", "United States",
                  "Gross domestic product, constant prices", "note",
                  "National currency", "Billions", "cnote",
                  "22,671.1", "23,305.0", "23,724.5", "24,127.8", "24,610.4",
                  "2024", sep = "\t")
  de_gdp <- paste("134", "DEU", "NGDP_RPCH", "Germany",
                  "Gross domestic product, constant prices", "note",
                  "Percent change", "Units", "cnote",
                  "-0.3", "-0.2", "n/a", "0.9", "1.4", "2024", sep = "\t")
  c(hdr, us_gdp, us_lvl, de_gdp, "")  # real files end with a blank/footer line
}

test_that("weo_table parses decoded bulk-file lines into a keyed table", {
  dt <- weo_table(weo_fixture_lines())
  expect_true(all(c("ISO", "WEO Subject Code", "Estimates Start After", "2025")
                  %in% names(dt)))
  expect_identical(nrow(dt), 3L)  # footer/blank lines dropped
  expect_identical(dt$ISO, c("USA", "USA", "DEU"))
  # some editions carry a trailing tab -> an unnamed column, silently dropped
  dt2 <- weo_table(paste0(weo_fixture_lines()[1:2], "\t"))
  expect_false(any(!nzchar(names(dt2))))
  expect_identical(names(dt2), names(dt))
})

test_that("weo_subset keeps only the requested subject", {
  dt <- weo_subset(weo_table(weo_fixture_lines()))
  expect_identical(unique(dt$`WEO Subject Code`), "NGDP_RPCH")
  expect_identical(nrow(dt), 2L)
})

test_that("weo_forecast_rows keeps only years beyond Estimates Start After", {
  rows <- weo_forecast_rows(weo_subset(weo_table(weo_fixture_lines())),
                            year = 2025, month = 4)
  us <- rows[region == "US"]
  # ESA = 2024 -> 2025..2027 are forecasts; 2023/2024 are history and excluded
  expect_identical(sort(us$target_period), c("2025", "2026", "2027"))
  expect_identical(us[target_period == "2025", value_native], 1.8)
})

test_that("weo_forecast_rows emits archive-schema forecast rows", {
  rows <- weo_forecast_rows(weo_subset(weo_table(weo_fixture_lines())),
                            year = 2025, month = 4)
  expect_true(all(rows$source == "imf_weo"))
  expect_true(all(rows$variable == "rgdp_growth"))
  expect_true(all(rows$unit_native == "yoy_pct"))     # calendar-year avg growth,
  expect_true(all(rows$output_type == "point"))       # same convention as spf_ecb annual
  expect_true(all(rows$declared_target == "unspecified"))
  # publication approximated mid-month, like the Philly SPF convention
  expect_true(all(rows$forecast_date == as.Date("2025-04-15")))
  oct <- weo_forecast_rows(weo_subset(weo_table(weo_fixture_lines())),
                           year = 2025, month = 10)
  expect_true(all(oct$forecast_date == as.Date("2025-10-15")))
})

test_that("weo_forecast_rows maps only requested regions; n/a values drop out", {
  dt <- weo_subset(weo_table(weo_fixture_lines()))
  us_only <- weo_forecast_rows(dt, year = 2025, month = 4)
  expect_identical(unique(us_only$region), "US")      # default: US
  both <- weo_forecast_rows(dt, year = 2025, month = 4,
                            regions = c(USA = "US", DEU = "DE"))
  de <- both[region == "DE"]
  expect_identical(sort(de$target_period), c("2026", "2027"))  # 2025 is n/a
})

test_that("weo_forecast_rows strips thousands separators when parsing values", {
  dt <- weo_table(weo_fixture_lines())
  lvl <- weo_forecast_rows(weo_subset(dt, subject = "NGDP_R"),
                           year = 2025, month = 4)
  expect_identical(lvl[target_period == "2025", value_native], 23724.5)
})

test_that("weo_read_lines survives cp1252 bytes in the legacy files' notes", {
  # pre-2021 bulk files are windows-1252: a curly quote (0x92) inside a notes
  # field must not truncate the line or lose the rows that follow it
  lines <- weo_fixture_lines()[1:4]
  parts <- strsplit(paste0(paste(lines, collapse = "\r\n"), "\r\n"), "note", fixed = TRUE)[[1]]
  bytes <- c(charToRaw(parts[1]), charToRaw("purchasers"), as.raw(0x92),
             charToRaw(" note"), charToRaw(paste(parts[-1], collapse = "note")))
  f <- tempfile(fileext = ".xls")
  con <- file(f, open = "wb")
  writeBin(bytes, con)
  close(con)
  got <- weo_read_lines(f)
  expect_identical(length(got), 4L)
  expect_identical(nrow(weo_subset(weo_table(got))), 2L)
})

test_that("weo_read_lines decodes UTF-16LE (BOM) and UTF-8 files identically", {
  lines <- weo_fixture_lines()
  f8 <- tempfile(fileext = ".tsv")
  writeLines(lines, f8, useBytes = TRUE)
  f16 <- tempfile(fileext = ".xls")
  con <- file(f16, open = "wb")
  writeBin(as.raw(c(0xFF, 0xFE)), con)  # UTF-16LE BOM, as the IMF bulk files ship
  writeBin(iconv(paste0(paste(lines, collapse = "\r\n"), "\r\n"),
                 to = "UTF-16LE", toRaw = TRUE)[[1]], con)
  close(con)
  expect_identical(weo_read_lines(f16), weo_read_lines(f8))
  expect_identical(weo_table(weo_read_lines(f16))$ISO, c("USA", "USA", "DEU"))
  # the 2024-onward bulk files are UTF-16LE with NO BOM
  f16nb <- tempfile(fileext = ".xls")
  con <- file(f16nb, open = "wb")
  writeBin(iconv(paste0(paste(lines, collapse = "\r\n"), "\r\n"),
                 to = "UTF-16LE", toRaw = TRUE)[[1]], con)
  close(con)
  expect_identical(weo_read_lines(f16nb), weo_read_lines(f8))
})
