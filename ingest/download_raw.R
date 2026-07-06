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
  spf_ecb = list(
    url = "https://www.ecb.europa.eu/stats/prices/indic/forecast/shared/files/SPF_individual_forecasts.zip",
    file = "spf_ecb_individual.zip",
    notes = "ECB SPF individual forecasts, all rounds since 1999Q1 (one CSV per round)."
  )
)

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
    cat(sprintf("[get ] %s: %s\n", sid, src$url))
    ok <- tryCatch({ download_one(src$url, dest); TRUE },
                   error = function(e) { message(sprintf("[FAIL] %s: %s", sid, conditionMessage(e))); FALSE })
    if (!ok) { failures <- c(failures, sid); next }
    manifest[[src$file]] <- manifest_entry(sid, src, dest)
    cat(sprintf("[ ok ] %s: %s bytes\n", sid, format(file.size(dest), big.mark = ",")))
  }

  jsonlite::write_json(manifest, manifest_path, auto_unbox = TRUE, pretty = TRUE)
  cat(sprintf("manifest: %s (%d files)\n", manifest_path, length(manifest)))
  if (length(failures)) 1L else 0L
}

if (sys.nframe() == 0L) quit(status = download_main(commandArgs(TRUE)))
