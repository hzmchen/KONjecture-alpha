#!/usr/bin/env Rscript
# Download raw upstream files into data/raw/ with a provenance manifest.
#
# Polite by design: one GET per file, descriptive User-Agent, and existing
# files are NOT re-downloaded unless --refresh is passed (append-only cache,
# see docs/schema.md). No API keys are used; ALFRED (needs a key) is deferred
# and documented in ingest/README.md.
#
# Usage: Rscript ingest/download_raw.R [--refresh] [--only id1 id2 ...]

dl_get_root <- function() {
  env <- Sys.getenv("KONJ_ROOT")
  if (nzchar(env)) return(normalizePath(env))
  arg <- grep("--file=", commandArgs(FALSE), value = TRUE)
  if (length(arg)) return(normalizePath(file.path(dirname(sub("--file=", "", arg[1])), "..")))
  normalizePath(getwd())
}

UA <- "KONjecture-alpha archive seeding (one-off bulk download; contact: news378@team706.com)"

# the WEO trim hook reuses the package's encoding-aware reader
source(file.path(dl_get_root(), "konjecture", "R", "weo.R"))

DL_SOURCES <- list(
  gdpnow = list(
    url = "https://www.atlantafed.org/-/media/Project/Atlanta/FRBA/Documents/cqer/researchcq/gdpnow/GDPTrackingModelDataAndForecasts.xlsx",
    file = "gdpnow_tracking.xlsx",
    notes = "Atlanta Fed GDPNow: TrackingDeepArchives / TrackingArchives / TrackRecord tabs; TrackRecord includes BEA advance estimates (outcome vintage 'advance')."
  ),
  nyfed = list(
    url = "https://www.newyorkfed.org/medialibrary/Research/Interactives/Data/NowCast/Downloads/New-York-Fed-Staff-Nowcast_download_data.xlsx",
    file = "nyfed_staff_nowcast.xlsx",
    notes = "NY Fed Staff Nowcast historical data (2016-2021 era and 2023- relaunch)."
  ),
  spf_philly_meangrowth = list(
    url = "https://www.philadelphiafed.org/-/media/frbp/assets/surveys-and-data/survey-of-professional-forecasters/historical-data/meangrowth.xlsx",
    file = "spf_philly_meangrowth.xlsx",
    notes = "Philadelphia Fed SPF mean growth-rate forecasts (RGDP tab = SAAR q/q %, quarterly rounds since 1968)."
  ),
  fred_monthly = list(
    url = "https://fred.stlouisfed.org/graph/fredgraph.csv?id=INDPRO,PAYEMS,RSAFS,UNRATE,DGORDER",
    file = "fred_monthly_indicators.csv",
    notes = "N2 spike inputs: monthly US indicators (industrial production, payrolls, retail sales, unemployment, durable goods orders), latest vintage via keyless fredgraph endpoint. Vintage-correct pulls need ALFRED (deferred, API key)."
  ),
  fred_gdp = list(
    url = "https://fred.stlouisfed.org/graph/fredgraph.csv?id=A191RL1Q225SBEA",
    file = "fred_gdp_growth.csv",
    notes = "N2 spike target: US real GDP growth (SAAR %, quarterly, latest vintage)."
  ),
  nyfed_legacy = list(
    url = "https://www.newyorkfed.org/medialibrary/media/research/policy/nowcast/new-york-fed-staff-nowcast_data_2002-present.xlsx",
    file = "nyfed_staff_nowcast_legacy.xlsx",
    notes = "NY Fed Staff Nowcast legacy file (old interactive, retired 2021): weekly nowcasts 2016-04->2021-09 plus pre-2016 retro model estimates (not published in real time - kept apart as nyfed_retro)."
  ),
  ecb_rtd_gdp = list(
    url = "https://data-api.ecb.europa.eu/service/data/RTD/Q.S0.S.G_GDPM_TO_C.E?format=csvdata&includeHistory=true",
    file = "ecb_rtd_gdp_ea.csv",
    notes = "ECB Real-Time Database: euro-area real GDP level (chain-linked volumes, SA), ALL vintages via SDMX includeHistory (VALID_FROM = publication timestamp). EA outcome vintages; note RTD first capture may lag the Eurostat flash (D1 caveat)."
  ),
  spf_ecb = list(
    url = "https://www.ecb.europa.eu/stats/prices/indic/forecast/shared/files/SPF_individual_forecasts.zip",
    file = "spf_ecb_individual.zip",
    notes = "ECB SPF individual forecasts, all rounds since 1999Q1 (one CSV per round)."
  )
)

# --- X8: IMF WEO database vintages (Apr + Oct editions) -----------------------
# Each edition's "all countries" bulk file (UTF-16LE TSV behind .ashx) is ~6-14
# MB; the trim hook keeps only the NGDP_RPCH rows (real GDP growth, all
# countries — X4 region expansion needs no re-download) re-encoded as UTF-8, so
# the committed cache stays small. The IMF moved the files under a month
# subdirectory from 2024 on; both layouts are tried via alt_urls.

weo_trim_ngdp_rpch <- function(dest) {
  lines <- weo_read_lines(dest)
  if (!grepl("WEO Subject Code", lines[1], fixed = TRUE))
    stop("payload is not a WEO bulk table (error page?)")
  keep <- c(1L, which(grepl("\tNGDP_RPCH\t", lines, fixed = TRUE)))
  if (length(keep) < 2L) stop("no NGDP_RPCH rows in payload")
  writeLines(lines[keep], dest, useBytes = TRUE)
}

weo_source <- function(year, month) {
  edition <- month %/% 6L + 1L  # 1 = April, 2 = October
  mon3 <- c("Apr", "Oct")[edition]
  monf <- c("April", "October")[edition]
  media <- "https://www.imf.org/-/media/files/publications/weo/weo-database"
  legacy <- "https://www.imf.org/external/pubs/ft/weo"
  fname <- tolower(sprintf("WEO%s%dall", mon3, year))
  # the CDN blob paths are all-lowercase (verified against the editions'
  # download pages); layout varies by era, so several are tried in turn
  urls <- c(
    sprintf("%s/%d/%s/%s.xls", media, year, tolower(monf), fname),   # 2021->
    sprintf("%s/%d/%s/%s.ashx", media, year, tolower(monf), fname),
    sprintf("%s/%d/%02d/%s.xls", media, year, edition, fname),       # ~2020 transitional
    sprintf("%s/%d/%02d/%s.ashx", media, year, edition, fname),
    sprintf("%s/%d/%s.xls", media, year, fname),                     # 2018-2019 year root
    sprintf("%s/%d/%s.ashx", media, year, fname),
    # pre-2021 layout on the classic host: /{year}/{01=April,02=October}/weodata/
    sprintf("%s/%d/%02d/weodata/%s.xls", legacy, year, edition, fname),
    sprintf("%s/%d/%02d/weodata/%s.ashx", legacy, year, edition, fname)
  )
  list(
    url = urls[1], alt_urls = urls[-1],
    file = sprintf("weo_%d_%02d.tsv", year, month),
    trim = weo_trim_ngdp_rpch,
    notes = sprintf(paste("IMF WEO database, %s %d edition: bulk 'all countries' file,",
                          "trimmed at retrieval to the NGDP_RPCH rows (real GDP growth,",
                          "annual %%, all countries) and re-encoded UTF-8; sha256 is of",
                          "the trimmed file."), monf, year)
  )
}

for (.y in 2018:2026) for (.m in c(4L, 10L)) {
  if (.y == 2026 && .m == 10L) next  # not published yet
  DL_SOURCES[[sprintf("weo_%d_%02d", .y, .m)]] <- weo_source(.y, .m)
}
rm(.y, .m)

download_one <- function(url, dest, ua = UA) {
  h <- curl::new_handle(useragent = ua, timeout = 120, followlocation = TRUE)
  curl::curl_download(url, dest, handle = h, quiet = TRUE)
}

manifest_entry <- function(sid, src, dest) {
  list(
    source_id = sid,
    url = src$url,
    retrieved_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z", tz = "UTC"),
    sha256 = digest::digest(file = dest, algo = "sha256"),
    bytes = file.size(dest),
    notes = src$notes
  )
}

download_main <- function(args = character(), root = dl_get_root()) {
  raw_dir <- file.path(root, "data", "raw")
  manifest_path <- file.path(raw_dir, "manifest.json")
  refresh <- "--refresh" %in% args
  only <- if ("--only" %in% args) args[seq(which(args == "--only") + 1, length(args))] else names(DL_SOURCES)

  dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
  manifest <- if (file.exists(manifest_path)) jsonlite::read_json(manifest_path) else list()
  failures <- character()

  for (sid in names(DL_SOURCES)) {
    if (!sid %in% only) next
    src <- DL_SOURCES[[sid]]
    dest <- file.path(raw_dir, src$file)
    if (file.exists(dest) && !refresh) {
      cat(sprintf("[skip] %s: cached (%s)\n", sid, src$file))
      next
    }
    served <- NULL
    err <- NULL
    for (u in c(src$url, src$alt_urls)) {  # primary first, then known layout moves
      cat(sprintf("[get ] %s: %s\n", sid, u))
      # a trim hook doubles as payload validation: CDNs can answer HTTP 200
      # with an error page, so a rejected payload advances to the next url
      hit <- tryCatch({
        download_one(u, dest)
        if (!is.null(src$trim)) src$trim(dest)
        TRUE
      }, error = function(e) { err <<- conditionMessage(e); FALSE })
      if (hit) { served <- u; break }
    }
    if (is.null(served)) {
      if (file.exists(dest)) file.remove(dest)  # no stub to shadow future runs
      message(sprintf("[FAIL] %s: %s", sid, err))
      failures <- c(failures, sid)
      next
    }
    src$url <- served  # the manifest records the url that actually served the file
    manifest[[src$file]] <- manifest_entry(sid, src, dest)
    cat(sprintf("[ ok ] %s: %s bytes\n", sid, format(file.size(dest), big.mark = ",")))
  }

  jsonlite::write_json(manifest, manifest_path, auto_unbox = TRUE, pretty = TRUE)
  cat(sprintf("manifest: %s (%d files)\n", manifest_path, length(manifest)))
  if (length(failures)) 1L else 0L
}

if (sys.nframe() == 0L) quit(status = download_main(commandArgs(TRUE)))
