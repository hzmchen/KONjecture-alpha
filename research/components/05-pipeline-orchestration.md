# Pipeline, Compute, Reproducibility, Scheduling (C8 backend)

**Verified 2026-06-10** from CRAN/GitHub ([method](README.md)). Requirement recap ([03 §5](../03-synthesis-market-gap-and-fit.md), [08](../08-pre-mortem.md)): everything computes offline, caches aggressively, resumes cleanly after months untouched, fails loud.

## 1. Pipeline core (rOpenSci, all MIT, all active)

| Component | Capabilities | Status [V] | License [V] | Availability | Verdict |
|---|---|---|---|---|---|
| **`targets`** | Make-like DAG pipeline: skips up-to-date tasks, content-addressed caching — the dormancy-resume mechanism in software form | 1.12.0, 2026-02-09 | MIT | CRAN; WASM ✓ (irrelevant but verified) | **Adopt** — pipeline backbone (N2) |
| `tarchetypes` | Target archetypes (files, literate programming, branching sugar) | 0.14.1, 2026-03-24 | MIT | CRAN | Adopt alongside targets |
| `crew` | Distributed workers for targets (local, HPC, cloud) | 1.3.1, 2026-05-30 — very active | MIT | CRAN | Adopt **only when needed** — v0 compute (a few models × regions) fits a single CI runner; crew is the proven scale-up path, not a day-1 dependency |

## 2. Reproducibility & interop

| Component | Capabilities | Status [V] | License [V] | Availability | Verdict |
|---|---|---|---|---|---|
| `renv` | Project-local package library + lockfile; supports r-universe repos (needed for hubverse pinning, [03 §1](03-formats-validation-scoring.md)) | 1.2.3, 2026-05-16 | MIT | CRAN | **Adopt from day 1** — the lockfile *is* the dormancy insurance for the package layer |
| `reticulate` | R↔Python bridge (statsmodels, nowcast_lstm adapters) | 1.46.0, 2026-04-09 | Apache-2 | CRAN | Adopt at X3 (second model language), not before — each language doubles the environment surface |
| Docker / Rocker images | Frozen system environment for CI runs | Rocker project, versioned R images, actively published | GPL-2 (images: per-content) | Docker Hub/GHCR | Optional hardening: pin `rocker/r-ver:<version>` in CI for bit-reproducible wake-ups |

## 3. Scheduling / CI (the "server" that isn't one)

| Component | Capabilities | Status | Licensing/cost | Verdict |
|---|---|---|---|---|
| **GitHub Actions (cron)** | Scheduled + event-triggered workflows; free for public repos; 6 h/job limit | platform, ubiquitous | free (public repos) | **Adopt** — the zero-standing-infra scheduler the architecture assumes |
| r-lib/actions + `setup-r`/`setup-renv` | Maintained R toolchain actions | active (Posit/r-lib) | MIT | Adopt for CI setup |
| Cron alternatives (GitLab CI, Cloudflare Workers cron) | same shape | — | free tiers | Fallback only; no lock-in concern since pipeline is plain R |

**Dormancy trap, verified platform behavior [S]:** GitHub **disables scheduled workflows after 60 days without repo activity** (public repos). For KONjecture this is double-edged: it auto-stops compute when the hobby pauses (good — no zombie spend), but it also means the dashboard silently stops updating, which is exactly the failure shape [08 F3](../08-pre-mortem.md) targets. The **self-announcing staleness requirement (X5) must therefore live in the *artifact*, not the pipeline**: the page must render its own "last updated / dormant since" banner from the artifact timestamp, never assume a heartbeat. Design consequence, no extra component needed.

## 4. Layer assessment

- The C8 stack is **mature, MIT-licensed, single-vendor-free** (rOpenSci + platform CI) and matches the [01 §7](../01-supply-existing-frameworks.md) assessment with 2026-fresh versions; nothing here is stale or pre-1.0.
- Total standing infrastructure required: **zero processes, one cron entry, one CI secret (FRED key)** — consistent with R7 dormancy tolerance.

## References

CRAN canonical pages, fetched 2026-06-10 [V]; [GitHub Docs — disabling scheduled workflows in inactive repositories](https://docs.github.com/en/actions/managing-workflow-runs/disabling-and-enabling-a-workflow) (A) [S]; [rOpenSci targets docs](https://books.ropensci.org/targets/) (B) [S]; [Rocker project](https://rocker-project.org/) (B) [S].
