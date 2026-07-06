# site_lib.R — pure helpers unit-tested; page rendering regression-tested
# byte-for-byte against the committed site/index.html.

root <- Sys.getenv("KONJ_ROOT")

test_that("nice_ticks produces round, ascending, in-range ticks", {
  expect_equal(nice_ticks(0, 10), c(0, 2, 4, 6, 8, 10))
  t <- nice_ticks(-1.37, 4.62)
  expect_true(all(diff(t) > 0))
  expect_true(min(t) >= -1.37 && max(t) <= 4.62 + 1e-9)
  expect_equal(nice_ticks(-6.4297, 12.0711, 7), c(-5, 0, 5, 10))
})

test_that("scales map endpoints exactly", {
  fy <- yscale(0, 10, 296, 16)
  expect_equal(fy(0), 296)
  expect_equal(fy(10), 16)
  d <- as.Date(c("2026-04-30", "2026-05-30", "2026-07-03"))
  xs <- xscale(d, 46, 710)
  expect_equal(xs$f(d[1]), 46)
  expect_equal(xs$f(d[3]), 710)
  expect_identical(c(xs$lo, xs$hi), d[c(1, 3)])
})

test_that("esc escapes html and formatting helpers are C-style", {
  expect_identical(esc("a&b<c>d"), "a&amp;b&lt;c&gt;d")
  expect_identical(f1(36), "36.0")
  expect_identical(f2(1.189), "1.19")
  expect_identical(fg(2.5), "2.5")
  expect_identical(fg(2), "2")
})

test_that("replace_all is literal-safe for '&' and trailing matches (gsub regression)", {
  expect_identical(replace_all("x $K y", "$K", "a&amp;b"), "x a&amp;b y")
  expect_identical(replace_all("$K.$K", "$K", "\\1&"), "\\1&.\\1&")
  expect_identical(replace_all("end $K", "$K", "z"), "end z")
})

with_ctx <- function() {
  fc <- as.data.table(nanoparquet::read_parquet(file.path(root, "data/archive/forecasts.parquet")))
  oc <- as.data.table(nanoparquet::read_parquet(file.path(root, "data/archive/outcomes.parquet")))
  manifest <- jsonlite::read_json(file.path(root, "data/raw/manifest.json"))
  build_context(fc, oc, manifest)
}

test_that("build_context derives the page state from the archive", {
  ctx <- with_ctx()
  expect_identical(ctx$q_now, "2026Q2")
  expect_length(ctx$rows, 12)
  expect_length(ctx$common, 12)
  expect_named(ctx$mae, c("gdpnow", "nyfed", "spf_philly"))
  expect_identical(ctx$data_as_of, "2026-07-06")
  expect_identical(format(ctx$ecb_last_round), "2026-04-15")
  expect_true(ctx$gdpnow_full_mae > 0 && length(ctx$full) == 59)
  # every tracked quarter's advance estimate is present in every row
  expect_true(all(vapply(ctx$rows, function(r) is.finite(r$advance), TRUE)))
})

test_that("render_page reproduces the committed page byte-for-byte", {
  ctx <- with_ctx()
  template <- paste0(paste(readLines(file.path(root, "site/template.html"), warn = FALSE),
                           collapse = "\n"), "\n")
  committed <- readChar(file.path(root, "site/index.html"),
                        file.size(file.path(root, "site/index.html")))
  built_at <- sub('.*page built <strong>(\\d{4}-\\d{2}-\\d{2}).*', "\\1", committed)
  html <- render_page(ctx, template, built_at)
  expect_identical(html, committed)
  expect_false(grepl("\\$[A-Z_]{3,}", html))  # no unfilled placeholders
})

test_that("a source with no data degrades gracefully instead of crashing the build", {
  # dormancy scenario: a provider track goes dark (research/07's rot vector)
  fc <- as.data.table(nanoparquet::read_parquet(file.path(root, "data/archive/forecasts.parquet")))
  oc <- as.data.table(nanoparquet::read_parquet(file.path(root, "data/archive/outcomes.parquet")))
  manifest <- jsonlite::read_json(file.path(root, "data/raw/manifest.json"))

  expect_null(final_before(fc[region == "US"], "nyfed", "2015Q1", as.Date("2015-04-30")))

  ctx <- build_context(fc[source != "nyfed"], oc, manifest)
  expect_true(all(vapply(ctx$rows, function(r) is.null(r$nyfed), TRUE)))
  expect_identical(nrow(ctx$evo$nyfed), 0L)
  for (fragment in list(tiles(ctx), table_view(ctx), chart_evolution(ctx), chart_trackrecord(ctx)))
    expect_type(fragment, "character")
  expect_false(grepl("NY Fed Staff Nowcast [0-9]", chart_evolution(ctx)))  # no direct label

  # kills the full-history MAE loop; mean(NULL) warns, which is acceptable here
  ctx2 <- suppressWarnings(build_context(fc[source != "gdpnow"], oc, manifest))
  expect_length(ctx2$full, 0)
  expect_type(chart_trackrecord(ctx2), "character")
})

test_that("site_main writes the page for an arbitrary root", {
  tmp <- tempfile("siteroot")
  for (d in c("data/archive", "data/raw", "site")) dir.create(file.path(tmp, d), recursive = TRUE)
  for (f in c("data/archive/forecasts.parquet", "data/archive/outcomes.parquet",
              "data/raw/manifest.json", "site/template.html"))
    file.copy(file.path(root, f), file.path(tmp, f))
  out <- site_main(tmp, built_at = "2026-07-06")
  expect_true(file.exists(out))
  expect_identical(readLines(out, warn = FALSE), readLines(file.path(root, "site/index.html"), warn = FALSE))
})
