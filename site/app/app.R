# X5: shinylive app skeleton — Now / Compare / Scores over the precomputed
# archive. Thin usage layer (CLAUDE.md ground rule 1): all logic is konjecture
# package code (bundled as R/site_lib.R by export.R, since the package is not
# on the webR binary repo); the app only wires tested functions to inputs.
# Renders precomputed artifacts only — no models, no network (05 RS4 / I2).
library(shiny)
suppressMessages(library(data.table))

source("R/site_lib.R")

fc <- as.data.table(nanoparquet::read_parquet("data/forecasts.parquet"))
oc <- as.data.table(nanoparquet::read_parquet("data/outcomes.parquet"))
manifest <- jsonlite::read_json("data/manifest.json")
ss <- as.data.table(nanoparquet::read_parquet("data/scores_summary.parquet"))
ctx <- build_context(fc, oc, manifest, scores_summary = ss)

staleness <- function(ctx) {
  days <- as.integer(Sys.Date() - as.Date(ctx$data_as_of))
  cls <- if (days > 45) "color:#8a1f1f" else if (days > 14) "color:#6b4d00" else "color:#52514e"
  sprintf("<p style='font-size:13px;%s'>Data retrieved %s (%d days ago). Static snapshot; updates are event-driven, no schedule promised; staleness is announced, not hidden (08 F3).</p>",
          cls, ctx$data_as_of, days)
}

chart_css <- "svg{max-width:100%;height:auto} .line{fill:none;stroke-width:2}
.s1{stroke:#2a78d6;color:#2a78d6}.s2{stroke:#1baf7a;color:#1baf7a}.s3{stroke:#eda100;color:#eda100}
.dot.s1{fill:#2a78d6}.dot.s2{fill:#1baf7a}.dot.s3{fill:#eda100}.dot{stroke:none}
.stem{stroke-width:2}.grid{stroke:#e1e0d9}.axis{stroke:#c3c2b7}
.tick,.ylab,.dl{font:11px system-ui}.dl{font-weight:600}
.adv{fill:#0b0b0b}.hit{fill:transparent}
table{border-collapse:collapse;font:13.5px system-ui}td,th{padding:4px 10px;border-bottom:1px solid #e1e0d9}"

ui <- fluidPage(
  tags$head(tags$style(HTML(chart_css))),
  titlePanel(sprintf("KONjecture — %s US GDP nowcasts (skeleton)", ctx$q_now)),
  HTML(staleness(ctx)),
  tabsetPanel(
    tabPanel("Now", h4("Evolution of the current-quarter nowcast"),
             htmlOutput("evolution")),
    tabPanel("Compare", h4("Final nowcast vs BEA advance, last 12 quarters"),
             htmlOutput("trackrecord"),
             h4("Review: errors vs first print"), htmlOutput("errors")),
    tabPanel("Scores", h4("Scores by horizon (D4: first print + settled)"),
             htmlOutput("scores"))
  ),
  HTML("<p style='font-size:12px;color:#898781'>Charts are the same tested SVG builders as the static page; declared target per source, regions never pooled.</p>")
)

server <- function(input, output, session) {
  output$evolution   <- renderUI(HTML(chart_evolution(ctx)))
  output$trackrecord <- renderUI(HTML(chart_trackrecord(ctx)))
  output$errors      <- renderUI(HTML(chart_errors(ctx)))
  output$scores      <- renderUI(HTML(scores_table(ctx$scores_summary)))
}

shinyApp(ui, server)
