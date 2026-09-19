# KONjecture-alpha — working rules

GDP-nowcast archive + comparison site, pure R. Build: `cd pipeline && Rscript -e 'targets::tar_make()'`. Tests: `Rscript tests/run_tests.R` (offline) · coverage: `Rscript tests/coverage.R`. Network only via deliberate `Rscript ingest/download_raw.R`. Task board: [TODO.md](TODO.md).

## Ground rules

### 1. Split functionality from usage

Anything that is core functionality — data transforms, archive/schema logic, scoring, model adapters, chart builders; anything that could be invoked from more than one context — lives in an **R package**. Usage layers (`pipeline/_targets.R`, `ingest/` scripts, `site/` generation, dashboards) stay thin: they wire package functions together, hold the paths/config, and do the I/O orchestration.

Package code must be modular, composable, reusable:

- small functions that do one thing and return values (no hidden state, no global side effects);
- no hard-coded file paths, URLs, or context assumptions inside package functions — those are arguments, supplied by the usage layer;
- side effects (disk, network, rendering) pushed to the edges; the core operates on data in, data out.

When touching existing code that violates this (e.g. `pipeline/R/`, `site/R/`, logic embedded in `ingest/` scripts), migrate it into the package rather than extending it in place.

### 2. Red/green TDD

New functionality starts with a failing test:

1. **Red** — write the test first, run it, and confirm it fails for the expected reason.
2. **Green** — write the minimal code to make it pass.
3. **Refactor** — clean up with the suite green.

No production code without a preceding failing test. Bug fixes start with a test that reproduces the bug. Tests stay offline (fixtures, not network) per the existing suite's convention.
