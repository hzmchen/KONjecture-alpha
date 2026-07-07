#!/usr/bin/env Rscript
# Generate site/index.html — the N3 Wizard-of-Oz nowcast comparison page.
#
# Static, self-contained (inline SVG + CSS + a little JS), built purely from
# data/archive/ + data/raw/manifest.json + site/template.html. No network.
# All logic lives in the konjecture package (konjecture/R/site_lib.R); this file is the
# thin runnable entry point. Design requirements implemented: self-announcing
# staleness (research/08 F3), dual-target disclosure (research/09 D4),
# per-source declared-target fairness note (research/09 §4).

suppressMessages(library(data.table))

site_get_root <- function() {
  env <- Sys.getenv("KONJ_ROOT")
  if (nzchar(env)) return(normalizePath(env))
  arg <- grep("--file=", commandArgs(FALSE), value = TRUE)
  if (length(arg)) return(normalizePath(file.path(dirname(sub("--file=", "", arg[1])), "..")))
  normalizePath(getwd())
}

source(file.path(site_get_root(), "konjecture", "R", "site_lib.R"))
if (sys.nframe() == 0L) site_main(site_get_root())
