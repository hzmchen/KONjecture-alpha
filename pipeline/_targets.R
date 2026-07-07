# Single entry point for the whole build: raw cache -> normalized archive ->
# nowcast models -> static site. Run from pipeline/:  Rscript -e 'targets::tar_make()'
# The network stage (ingest/download_raw.R) stays a separate, deliberate manual
# step — the pipeline itself never touches the network. See pipeline/README.md.
library(targets)
tar_source("../konjecture/R")  # the konjecture package; sourced (not installed) so targets tracks function definitions
tar_option_set(packages = c("dfms", "nanoparquet", "data.table"))

list(
  # --- raw cache (files tracked, never fetched here) ---
  tar_target(raw_gdpnow, "../data/raw/gdpnow_tracking.xlsx", format = "file"),
  tar_target(raw_nyfed, "../data/raw/nyfed_staff_nowcast.xlsx", format = "file"),
  tar_target(raw_philly, "../data/raw/spf_philly_meangrowth.xlsx", format = "file"),
  tar_target(raw_ecb, "../data/raw/spf_ecb_individual.zip", format = "file"),
  tar_target(raw_manifest, "../data/raw/manifest.json", format = "file"),
  tar_target(monthly_file, "../data/raw/fred_monthly_indicators.csv", format = "file"),
  tar_target(gdp_file, "../data/raw/fred_gdp_growth.csv", format = "file"),

  # --- N4: normalized vintage-correct archive (ingest/build_archive.R) ---
  tar_target(archive_script, "../ingest/build_archive.R", format = "file"),
  tar_target(archive_files,
             run_build_script(archive_script,
                              c(raw_gdpnow, raw_nyfed, raw_philly, raw_ecb, raw_manifest),
                              c("../data/archive/forecasts.parquet",
                                "../data/archive/outcomes.parquet",
                                "../data/archive/forecasts.csv",
                                "../data/archive/outcomes.csv")),
             format = "file"),

  # --- N2: nowcast models (latest-vintage FRED inputs) ---
  tar_target(monthly_raw, read_monthly(monthly_file)),
  tar_target(gdp, read_gdp(gdp_file)),
  tar_target(X, transform_monthly(monthly_raw)),
  tar_target(target_q, nowcast_quarter(gdp, X)),
  tar_target(fc_ar, ar_benchmark(gdp, target_q)),
  tar_target(fc_dfm, dfm_bridge(X, gdp, target_q)),
  tar_target(run_date, as.character(Sys.Date())),
  tar_target(model_output, rbind(as_model_output(fc_ar, run_date),
                                 as_model_output(fc_dfm, run_date))),
  tar_target(archived, append_model_output(model_output,
                                           "../data/archive/model_output.parquet"),
             format = "file"),

  # --- N3: static comparison page (site/build_site.R) ---
  tar_target(site_script, "../site/build_site.R", format = "file"),
  tar_target(site_lib, "../konjecture/R/site_lib.R", format = "file"),
  tar_target(site_template, "../site/template.html", format = "file"),
  tar_target(site_html,
             run_build_script(site_script, c(archive_files, site_lib, site_template, scores_files),
                              "../site/index.html"),
             format = "file"),

  # --- X2: scoring vs named target rules, stratified by horizon bucket ---
  tar_target(fc_archive, {
    invisible(archive_files)
    as.data.table(nanoparquet::read_parquet("../data/archive/forecasts.parquet"))
  }),
  tar_target(oc_archive, {
    invisible(archive_files)
    as.data.table(nanoparquet::read_parquet("../data/archive/outcomes.parquet"))
  }),
  tar_target(scores, score_first_release(fc_archive, oc_archive)),
  tar_target(scores_agg, score_summary(scores)),
  tar_target(scores_files, write_scores(scores, scores_agg, "../data/archive"),
             format = "file"),

  # --- X5 (Quarto fallback): static dashboard, only when the quarto CLI exists ---
  tar_target(dashboard_qmd, "../site/dashboard.qmd", format = "file"),
  tar_target(dashboard_html,
             render_dashboard(dashboard_qmd, c(archive_files, site_lib, scores_files),
                              "../site/dashboard.html"),
             format = "file")
)
