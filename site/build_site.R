#!/usr/bin/env Rscript
# Generate site/index.html — the N3 Wizard-of-Oz nowcast comparison page.
#
# Static, self-contained (inline SVG + CSS + a little JS), built purely from
# data/archive/ + data/raw/manifest.json + site/template.html. No network.
# Design requirements implemented: self-announcing staleness (research/08 F3),
# dual-target disclosure (research/09 D4), per-source declared-target fairness
# note (research/09 §4).

suppressMessages(library(data.table))
invisible(Sys.setlocale("LC_TIME", "C"))  # English month abbreviations in axis labels

ROOT <- normalizePath(file.path(dirname(sub("--file=", "", grep("--file=", commandArgs(FALSE), value = TRUE))), ".."))
OUT <- file.path(ROOT, "site", "index.html")

fc <- as.data.table(nanoparquet::read_parquet(file.path(ROOT, "data/archive/forecasts.parquet")))
oc <- as.data.table(nanoparquet::read_parquet(file.path(ROOT, "data/archive/outcomes.parquet")))
manifest <- jsonlite::read_json(file.path(ROOT, "data/raw/manifest.json"))

SOURCES <- list(  # display order = categorical slot order (validated palette)
  gdpnow = list(label = "Atlanta Fed GDPNow", cls = "s1"),
  nyfed = list(label = "NY Fed Staff Nowcast", cls = "s2"),
  spf_philly = list(label = "Philly Fed SPF (mean)", cls = "s3")
)

DATA_AS_OF <- max(vapply(manifest, function(m) substr(m$retrieved_at, 1, 10), ""))
BUILT_AT <- format(Sys.Date())

us <- fc[region == "US"]

# ---- latest quarter with live coverage ----
cover <- us[, .(n = uniqueN(source)), by = target_period]
q_now <- max(cover[n >= 2, target_period])
evo <- lapply(SOURCES, function(...) NULL)
for (s in names(SOURCES)) evo[[s]] <- us[source == s & target_period == q_now][order(forecast_date)]
adv_now <- oc[target_period == q_now & release_label == "advance"]

# ---- final-before-advance nowcast per completed quarter ----
completed <- oc[order(target_period)][seq(max(1, .N - 11), .N)]

final_before <- function(src, tp, pub) {
  d <- us[source == src & target_period == tp & forecast_date <= pub][order(forecast_date)]
  if (nrow(d)) d[.N] else NULL
}

rows <- lapply(seq_len(nrow(completed)), function(i) {
  o <- completed[i]
  r <- list(q = o$target_period, advance = o$value_native, pub = o$published_on)
  for (s in names(SOURCES)) {
    f <- final_before(s, o$target_period, o$published_on)
    r[[s]] <- if (is.null(f)) NULL else f$value_native
  }
  r
})

# ---- MAE on the common sample (all three sources present) ----
common <- Filter(function(r) all(vapply(names(SOURCES), function(s) !is.null(r[[s]]), TRUE)), rows)
mae <- sapply(names(SOURCES), function(s)
  mean(vapply(common, function(r) abs(r[[s]] - r$advance), 0)))

# full-history GDPNow MAE straight from the archive
full <- unlist(lapply(seq_len(nrow(oc)), function(i) {
  o <- oc[i]
  f <- final_before("gdpnow", o$target_period, o$published_on)
  if (is.null(f)) NULL else abs(f$value_native - o$value_native)
}))
gdpnow_full_mae <- mean(full)

# ---- ECB SPF latest round ----
ecb <- fc[source == "spf_ecb"]
ecb_last_round <- max(ecb$forecast_date)
ecb_latest <- ecb[forecast_date == ecb_last_round][order(target_period)]

esc <- function(x) gsub(">", "&gt;", gsub("<", "&lt;", gsub("&", "&amp;", as.character(x))))
f1 <- function(x) sprintf("%.1f", x)
f2 <- function(x) sprintf("%.2f", x)
fg <- function(x) sprintf("%g", x)

# ============ SVG helpers ============

xscale <- function(dates, x0, x1) {
  lo <- min(dates); hi <- max(dates)
  span <- max(as.integer(hi - lo), 1)
  list(f = function(d) x0 + as.integer(d - lo) / span * (x1 - x0), lo = lo, hi = hi)
}

yscale <- function(lo, hi, y0, y1) function(v) y0 + (v - lo) / (hi - lo) * (y1 - y0)

nice_ticks <- function(lo, hi, n = 5) {
  raw <- (hi - lo) / n
  step <- 10^floor(log10(raw))
  for (m in c(1, 2, 2.5, 5, 10)) if (step * m >= raw) { step <- step * m; break }
  ticks <- c(); t <- ceiling(lo / step) * step
  while (t <= hi + 1e-9) { ticks <- c(ticks, round(t, 6)); t <- t + step }
  ticks
}

chart_evolution <- function() {
  W <- 860; H <- 330; ml <- 46; mr <- 150; mt <- 16; mb <- 34
  pts <- Filter(nrow, lapply(evo, function(d) d[, .(forecast_date, value_native)]))
  alld <- as.Date(unlist(lapply(pts, `[[`, "forecast_date")))
  allv <- unlist(lapply(pts, `[[`, "value_native"))
  ylo <- min(allv) - 0.4; yhi <- max(allv) + 0.4
  xs <- xscale(alld, ml, W - mr); fx <- xs$f
  fy <- yscale(ylo, yhi, H - mb, mt)

  g <- character()
  for (t in nice_ticks(ylo, yhi)) {
    y <- fy(t)
    g <- c(g, sprintf('<line class="grid" x1="%d" y1="%s" x2="%d" y2="%s"/><text class="tick" x="%d" y="%s" text-anchor="end">%s</text>',
                      ml, f1(y), W - mr, f1(y), ml - 8, f1(y + 4), fg(t)))
  }
  m0 <- as.Date(format(xs$lo, "%Y-%m-01"))
  months <- seq(m0, xs$hi, by = "month")
  for (m in as.list(months[months >= xs$lo])) {
    g <- c(g, sprintf('<text class="tick" x="%s" y="%d" text-anchor="middle">%s</text>',
                      f1(fx(m)), H - mb + 18, format(m, "%b")))
  }
  g <- c(g, sprintf('<line class="axis" x1="%d" y1="%d" x2="%d" y2="%d"/>', ml, H - mb, W - mr, H - mb))

  hover <- character()
  for (s in names(SOURCES)) {
    if (is.null(pts[[s]])) next
    meta <- SOURCES[[s]]; p <- pts[[s]]
    if (nrow(p) > 1) {
      path <- paste0("M", paste(sprintf("%s,%s", f1(fx(p$forecast_date)), f1(fy(p$value_native))), collapse = " L"))
      g <- c(g, sprintf('<path class="line %s" d="%s"/>', meta$cls, path))
    }
    r <- if (nrow(p) == 1) "4" else "2.5"
    g <- c(g, sprintf('<circle class="dot %s" cx="%s" cy="%s" r="%s"/>',
                      meta$cls, f1(fx(p$forecast_date)), f1(fy(p$value_native)), r))
    hover <- c(hover, sprintf('<circle class="hit" cx="%s" cy="%s" r="11" data-tip="%s · %s · %s%% SAAR"/>',
                              f1(fx(p$forecast_date)), f1(fy(p$value_native)),
                              meta$label, format(p$forecast_date), f2(p$value_native)))
    dl <- p[.N]
    short <- trimws(sub("\\(.*$", "", meta$label))
    g <- c(g, sprintf('<text class="dl %s" x="%s" y="%s">%s %s</text>',
                      meta$cls, f1(fx(dl$forecast_date) + 8), f1(fy(dl$value_native) + 4),
                      esc(short), f2(dl$value_native)))
  }
  paste0(sprintf('<svg viewBox="0 0 %d %d" role="img" aria-label="Evolution of %s US GDP nowcasts">', W, H, q_now),
         paste(g, collapse = ""), paste(hover, collapse = ""), "</svg>")
}

chart_trackrecord <- function() {
  W <- 860; rh <- 34; ml <- 84; mr <- 30; mt <- 26; mb <- 30
  H <- mt + rh * length(rows) + mb
  vals <- unlist(lapply(rows, function(r) c(r$advance, unlist(r[names(SOURCES)]))))
  xlo <- min(vals) - 0.5; xhi <- max(vals) + 0.5
  fx <- yscale(xlo, xhi, ml, W - mr)  # linear map works for x too

  g <- character()
  for (t in nice_ticks(xlo, xhi, 7)) {
    x <- fx(t)
    g <- c(g, sprintf('<line class="grid" x1="%s" y1="%d" x2="%s" y2="%d"/><text class="tick" x="%s" y="%d" text-anchor="middle">%s</text>',
                      f1(x), mt, f1(x), H - mb, f1(x), H - mb + 18, fg(t)))
  }
  if (xlo < 0 && 0 < xhi)
    g <- c(g, sprintf('<line class="axis" x1="%s" y1="%d" x2="%s" y2="%d"/>', f1(fx(0)), mt, f1(fx(0)), H - mb))

  hover <- character()
  for (i in seq_along(rows)) {
    r <- rows[[length(rows) - i + 1]]
    y <- mt + (i - 1) * rh + rh / 2
    g <- c(g, sprintf('<text class="ylab" x="%d" y="%s" text-anchor="end">%s</text>', ml - 10, f1(y + 4), r$q))
    for (s in names(SOURCES)) {
      if (is.null(r[[s]])) next
      meta <- SOURCES[[s]]
      g <- c(g, sprintf('<circle class="dot %s" cx="%s" cy="%s" r="5"/>', meta$cls, f1(fx(r[[s]])), f1(y)))
      hover <- c(hover, sprintf('<circle class="hit" cx="%s" cy="%s" r="11" data-tip="%s · %s · %s%% (advance %s%%)"/>',
                                f1(fx(r[[s]])), f1(y), meta$label, r$q, f2(r[[s]]), f2(r$advance)))
    }
    x <- fx(r$advance)
    g <- c(g, sprintf('<path class="adv" d="M%s,%s l6,7 l-6,7 l-6,-7 z"/>', f1(x), f1(y - 7)))
    hover <- c(hover, sprintf('<circle class="hit" cx="%s" cy="%s" r="11" data-tip="BEA advance estimate · %s · %s%% (published %s)"/>',
                              f1(x), f1(y), r$q, f2(r$advance), format(r$pub)))
  }
  paste0(sprintf('<svg viewBox="0 0 %d %d" role="img" aria-label="Final nowcasts vs BEA advance estimate, last %d quarters">', W, H, length(rows)),
         paste(g, collapse = ""), paste(hover, collapse = ""), "</svg>")
}

# ============ HTML fragments ============

tiles <- function() {
  t <- character()
  for (s in names(SOURCES)) {
    if (!nrow(evo[[s]])) next
    meta <- SOURCES[[s]]; last <- evo[[s]][.N]
    t <- c(t, sprintf('<div class="tile"><div class="tile-k"><span class="chip %s"></span>%s</div>\n<div class="tile-v">%s<span class="tile-u">%% SAAR</span></div>\n<div class="tile-m">as of %s</div></div>',
                      meta$cls, esc(meta$label), f2(last$value_native), format(last$forecast_date)))
  }
  adv_txt <- if (nrow(adv_now)) f2(adv_now$value_native[1]) else "pending"
  adv_m <- if (nrow(adv_now)) paste0("published ", format(adv_now$published_on[1])) else "BEA release expected ~30 days after quarter end"
  t <- c(t, sprintf('<div class="tile"><div class="tile-k"><span class="chip adv-chip"></span>BEA advance estimate</div>\n<div class="tile-v">%s</div><div class="tile-m">%s</div></div>',
                    adv_txt, adv_m))
  paste(t, collapse = "\n")
}

table_view <- function() {
  head <- paste0(vapply(SOURCES, function(m) sprintf("<th>%s</th>", esc(m$label)), ""), collapse = "")
  body <- vapply(rev(rows), function(r) {
    cells <- paste0(vapply(names(SOURCES), function(s)
      sprintf("<td>%s</td>", if (is.null(r[[s]])) "" else f2(r[[s]])), ""), collapse = "")
    sprintf("<tr><td>%s</td>%s<td><strong>%s</strong></td><td>%s</td></tr>", r$q, cells, f2(r$advance), format(r$pub))
  }, "")
  maes <- paste0(sprintf("<td>%s</td>", f2(mae)), collapse = "")
  sprintf('<table><thead><tr><th>Quarter</th>%s<th>BEA advance</th><th>Advance published</th></tr></thead>\n<tbody>%s\n<tr class="mae"><td>MAE (common sample, n=%d)</td>%s<td>—</td><td>—</td></tr></tbody></table>',
          head, paste(body, collapse = ""), length(common), maes)
}

ecb_table <- function() {
  r <- sprintf("<tr><td>%s</td><td>%s</td></tr>", esc(ecb_latest$target_period), f2(ecb_latest$value_native))
  sprintf('<table class="narrow"><thead><tr><th>Target period</th><th>Mean point forecast (%% y-o-y)</th></tr></thead><tbody>%s</tbody></table>',
          paste(r, collapse = ""))
}

# ============ assemble ============

legend <- paste0(vapply(SOURCES, function(m)
  sprintf('<span><span class="chip %s"></span>%s</span>', m$cls, esc(m$label)), ""), collapse = "")

html <- paste0(paste(readLines(file.path(ROOT, "site", "template.html"), warn = FALSE), collapse = "\n"), "\n")
subst <- c(QNOW = q_now, DATA_AS_OF = DATA_AS_OF, BUILT_AT = BUILT_AT,
           TILES = tiles(), LEGEND = legend, CHART1 = chart_evolution(), CHART2 = chart_trackrecord(),
           TABLE = table_view(), ECBTABLE = ecb_table(),
           ECB_ROUND = format(ecb_last_round), GN_MAE = f2(gdpnow_full_mae), GN_N = as.character(length(full)))
# split/join instead of gsub: replacement text contains "&", which gsub would
# reinterpret as "the whole match" even under fixed=TRUE
replace_all <- function(x, pat, rep) {
  parts <- strsplit(x, pat, fixed = TRUE)[[1]]
  if (endsWith(x, pat)) parts <- c(parts, "")
  paste(parts, collapse = rep)
}
for (k in names(subst)) html <- replace_all(html, paste0("$", k), subst[[k]])

writeLines(html, OUT, sep = "")
cat(sprintf("wrote site/index.html (%s bytes) · quarter=%s · common MAE sample n=%d\n",
            format(nchar(html, type = "bytes"), big.mark = ","), q_now, length(common)))
