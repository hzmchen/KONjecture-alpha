# N2 riskiest-assumption spike: targets pipeline skeleton (see pipeline/README.md)
# Run from pipeline/:  Rscript -e 'targets::tar_make()'
library(targets)
tar_source("R/functions.R")
tar_option_set(packages = c("dfms", "nanoparquet"))

list(
  tar_target(monthly_file, "../data/raw/fred_monthly_indicators.csv", format = "file"),
  tar_target(gdp_file, "../data/raw/fred_gdp_growth.csv", format = "file"),
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
             format = "file")
)
