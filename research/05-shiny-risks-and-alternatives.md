# R Shiny as Delivery Technology: Risks and Alternatives

**Research date:** 2026-06-10 (v2) · Quote tags [V]/[S], grades A–D per [00](00-methodology-and-rubrics.md). **Premise:** Shiny is the *hobby choice* (Issue #1 specifies it; building in R/Shiny scores high on rubric R7 curiosity/learning). The question is therefore not "Shiny or not" but **which risks to manage and which deployment shape fits a Liebhaberei**.

## 1. Risks

| # | Risk | Evidence | Liebhaberei severity |
|---|------|----------|---------------------|
| RS1 | **Standing server = standing obligation.** A hosted Shiny app needs a process supervisor, OS/package updates, TLS, uptime attention — the opposite of dormancy tolerance (R7) | structural; this is the mechanism behind the niche's dead dashboards (cf. [01 §10 G6](01-supply-existing-frameworks.md)) | **High** |
| RS2 | **Single-process, single-threaded concurrency.** **[S]** "A given Shiny app process can only do one thing at a time: if it is fitting a model for one client, it cannot simultaneously serve up a CSV download for another client" (Joe Cheng, Posit, grade B). Open-source Shiny Server serves an app from **[S]** "one (single-threaded blocking) process … all requests are handled one by one in a queue" (grade C/B). Async (`promises`) **[S]** "helps a single Shiny process support more concurrent sessions without getting bogged down" but does not make sessions faster | B/C sources, consistent | Medium (only matters if the app computes per-request — avoidable by design) |
| RS3 | **Hosting cost/limits.** Free tiers (e.g. shinyapps.io) are constrained; paid tiers or self-hosting reintroduce RS1 plus money. Scaling solutions (Shiny Server Pro / Posit Connect / Kubernetes) are enterprise tooling — wrong weight class for a hobby | C sources + product pages | Medium |
| RS4 | **Compute-in-request-path temptation.** Letting users trigger re-estimation ("re-running forecasts" in the vision) turns RS2/RS3 from theoretical to acute | structural | High if indulged; low if all estimation lives in the offline pipeline |
| RS5 | **webR/shinylive limitations** (if chosen): **[V]** "It is not possible to install packages from source in webR … For the moment, providing pre-compiled WebAssembly binaries is the only supported way to install R packages in webR" (Posit, grade B). Consequence: a package with C++/Fortran code is usable only if a WASM binary exists in the webR repo — **must be checked per package** (e.g. `dfms` uses C++). Plus: app + packages download to every visitor (payload size), all data must be public, no server-side secrets | B sources, [V] | Medium (constrains, doesn't block: the app only *renders* precomputed artifacts) |
| RS6 | Ecosystem/bus-factor of Shiny itself | Posit-backed, huge user base; low risk | Low |

## 2. Alternatives

| Option | What it is | Pros | Cons | R7 dormancy fit |
|--------|-----------|------|------|------------------|
| **A1. Shiny on a server** (shinyapps.io / Posit Connect / self-host) | classic deployment | full interactivity; any package; private data possible | RS1–RS3 in full | **Poor** |
| **A2. Shinylive (Shiny compiled to WASM, static hosting)** | **[V]** "Shinylive is a new way to run Shiny entirely in the browser, without any need for a hosted server, using WebAssembly via the webR project"; deployable to **[S]** "GitHub Pages or Netlify"; bundles **[S]** "as many R package binaries as possible in the exported app", giving a "self-contained bundle that will never change over time" | zero server, zero ops, zero hosting cost; reproducible snapshot; stays 100% Shiny/R (hobby preserved) | RS5: WASM package availability, payload size, public data only, browser-side compute limits | **Excellent** |
| **A3. Quarto dashboards / static site rebuilt by CI** | nightly/event-triggered render of charts (+ client-side OJS/plotly interactivity) | simplest possible delivery; survives years untouched | interactivity limited (no reactive R server); "explore" mode shrinks to pre-baked views | **Excellent** |
| **A4. Static JSON + JS charting** (Observable Framework, ECharts…) | precomputed artifacts, JS front end | most durable & fastest UX | front end leaves R — violates the hobby premise | Excellent but off-premise |
| **A5. Python stacks** (Dash/Streamlit/Panel) | rewrite | none for this project | abandons R; same server problems anyway | n/a |

## 3. Recommendation (static-first, Shiny as a view layer)

1. **Architectural invariant:** the pipeline (`targets`) computes everything offline and writes versioned artifacts (parquet/JSON). The dashboard — whatever it is — only **renders artifacts**. This single rule neutralizes RS2/RS3/RS4 entirely and makes the dashboard technology swappable.
2. **Default deployment: A2 shinylive on GitHub Pages**, falling back to A3 (Quarto) for any view that doesn't need reactivity. CI (already needed for the data pipeline) republishes the static site; nothing serves at rest. Verify early which needed packages have webR/WASM binaries — if a visualization-layer package is missing, that's a cheap rebuild under P-B, since heavy estimation never runs in the app.
3. **A1 (real server) only if a concrete need emerges** (private data, heavy interactive exploration, API endpoints) — and then as a consciously accepted standing obligation, not a default.
4. The vision's "re-running forecasts and evaluations" interactively → **icebox** ([TODO](../TODO.md)): it is the feature most at odds with both RS4 and R7. Pre-computed scenario grids can fake 80% of it.

## References

| Ref | Source (grade) |
|---|---|
| 1 | [Posit — r-shinylive](https://posit-dev.github.io/r-shinylive/) (B) [V] |
| 2 | [Tidyverse blog — Shinylive 0.8.0](https://tidyverse.org/blog/2024/10/shinylive-0-8-0/) (B) [S] |
| 3 | [Stagg — Shiny Without a Server: webR & Shinylive](https://georgestagg.github.io/shiny-without-a-server-2023/) (C) [S] |
| 4 | [Cheng — Async programming in R and Shiny](https://medium.com/@joe.cheng/async-programming-in-r-and-shiny-ebe8c5010790) (B — Posit engineer) [S] |
| 5 | [Kim — Async Shiny and Its Limitation](https://jaehyeon.me/blog/2018-05-19-asyn-shiny-and-its-limitation/) (D) [S] |
| 6 | [PEARC'24 — Shiny Concurrency: Scaling Single-Threaded and Resource-Intensive Applications](https://dl.acm.org/doi/abs/10.1145/3626203.3670590) (A) [S] |
| 7 | [Posit — Scaling Shiny apps with async programming (rstudio::conf 2018)](https://resources.rstudio.com/resources/rstudioconf-2018/scaling-shiny-apps-with-async-programming/) (B) [S] |
