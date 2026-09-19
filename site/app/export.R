#!/usr/bin/env Rscript
# Assemble + export the shinylive bundle (X5). Deliberate manual step, like
# ingest/download_raw.R: needs the shinylive package and (first run) network
# for the WASM assets. Output goes to site/app/_dist (gitignored: each visitor
# asset is rebuildable; only app.R + this script are source).
# Run from anywhere: Rscript site/app/export.R [destdir]

app_get_root <- function() {
  env <- Sys.getenv("KONJ_ROOT")
  if (nzchar(env)) return(normalizePath(env))
  arg <- grep("--file=", commandArgs(FALSE), value = TRUE)
  if (length(arg)) return(normalizePath(file.path(dirname(sub("--file=", "", arg[1])), "..", "..")))
  normalizePath(getwd())
}

# staging dir: app.R + bundled konjecture core + precomputed archive slices
assemble_app <- function(root, staging = tempfile("konj_app")) {
  dir.create(file.path(staging, "R"), recursive = TRUE)
  dir.create(file.path(staging, "data"), recursive = TRUE)
  file.copy(file.path(root, "site/app/app.R"), staging)
  file.copy(file.path(root, "konjecture/R/site_lib.R"), file.path(staging, "R"))
  for (f in c("forecasts.parquet", "outcomes.parquet", "scores_summary.parquet"))
    file.copy(file.path(root, "data/archive", f), file.path(staging, "data"))
  file.copy(file.path(root, "data/raw/manifest.json"), file.path(staging, "data"))
  staging
}

if (sys.nframe() == 0L) {
  ROOT <- app_get_root()
  dest <- commandArgs(TRUE)
  dest <- if (length(dest)) dest[1] else file.path(ROOT, "site/app/_dist")
  app <- assemble_app(ROOT)
  shinylive::export(app, dest)
  cat(sprintf("exported %s -> %s (%.1f MB)\n", app, dest,
              sum(file.info(list.files(dest, recursive = TRUE, full.names = TRUE))$size) / 1e6))
}
