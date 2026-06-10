# Pre-Mortem: "It Is June 2028 and KONjecture Is Dead"

**Date:** 2026-06-10 · Method: Gary Klein's pre-mortem — assume the failure already happened, explain it, then immunize. Failure modes are grounded in the [graveyard cases C1–C9 and taxonomy T1–T7](07-graveyard-negative-cases.md); countermeasure status links to existing design decisions and [TODO](../TODO.md).

**Scenario:** The repo's last commit is fourteen months old. The dashboard, if it loads at all, shows nowcasts for a quarter long past. Issue #2 was never decided. Why?

## 1. Failure modes, ranked

Likelihood reflects the graveyard base rates (most projects die quietly, not dramatically); damage is to the project's accumulated value, not to ego.

| # | Failure narrative | Taxonomy | Likelihood | Damage | Early warnings | Countermeasures (status) |
|---|-------------------|----------|------------|--------|----------------|--------------------------|
| F1 | **Quiet abandonment.** Initial enthusiasm built the pipeline; the fifth weekend of ingestion-adapter debugging was a chore; another hobby won. The 61%-solo / 44%-burnout base rates did their work | T3, T5 | **High** (the default outcome) | Medium — *if* dormancy was designed for; High otherwise | skipped two fun audits; commits only fix breakage, add nothing | R7 gates + quarterly fun/obligation audits (in place, [03 §6](03-synthesis-market-gap-and-fit.md)); small-boring-core rule (in place); **no-streak rule: cadence is event-driven, never a calendar promise** (new, TODO X9) |
| F2 | **Upstream feed death.** A provider changed its API/format (or a source was discontinued, as happened to the OECD Tracker itself); ingestion failed silently for months; restarting felt like starting over | T1 | High over a multi-year horizon | Medium | red CI ignored; a source's last successful pull ages past one cycle | **fail-loud CI** + per-source **dependency register with fallback** (new, TODO X9); archive-first design means past value survives any feed's death (in place, [06](06-vintage-reconstruction.md)) |
| F3 | **Silent staleness embarrassment.** The site stayed up but stopped meaning anything — a "real-time" tracker showing last spring, quietly archived like C1, discovered via a snarky citation | T1+T7 | Medium | High (credibility is the asset) | "last updated" predates the current quarter | **self-announcing staleness**: last-updated banner + automatic dormant-mode notice when artifacts age out (new — design requirement on the dashboard, TODO X5/X9). Static delivery makes stale *honest*, not broken ([05](05-shiny-risks-and-alternatives.md)) |
| F4 | **Dependency cascade.** A transitive package got archived; CRAN/CI rot spread; the fix sat unmade (the `nowcasting`/`matlab` death, C3) | T2 | Medium | Low–Medium | dependency deprecation warnings in CI | thin-deps + vendor-small-pieces policy (in place, P-B, [03 §5](03-synthesis-market-gap-and-fit.md)); `renv` lockfile; CI canary job (TODO X9) |
| F5 | **Credibility shock.** A bad number got quoted somewhere visible; the maintainer, mortified, took it down — and never put it back. (The NY Fed's two-year suspension, C2, at hobby scale) | T4 | Low–Medium | High | uncertainty bands dropped from a chart "for clarity"; target measure still undecided | uncertainty-first UI (vision + [02 R-4](02-demand-users-and-requirements.md)); decide the target measure (Issue #2); publish own errors prominently — accountability as armor; GDPNow-style disclaimer wording ("not an official forecast") |
| F6 | **Obligation creep.** A handful of users came to expect freshness and answers; serving them became a job; quitting the job killed the project (C6's dynamic, solo) | T5 | Low–Medium | Medium | apologizing for delays; feature requests steering the roadmap | static, no-SLA delivery (in place, [05](05-shiny-risks-and-alternatives.md)); **explicit no-SLA note in README when the dashboard ships** (TODO X9); obligation audit (in place) |
| F7 | **Alt-data drift.** A Google-Trends-style input changed under the model and quietly poisoned the nowcasts (C8: input changed 86 times in two months) | T4 | Low (iceboxed) | High if indulged | any I4 item leaving the icebox without a drift monitor | icebox I4 holds; revisit condition already demands a tracked backtest improvement (in place, [TODO](../TODO.md)) |
| F8 | **Archive loss after death.** The repo/org vanished with the owner's account or a platform change; unlike C5/C6's good deaths, the accumulated point-in-time archive — the moat — evaporated like C9's article archive | T7 | Low | **Maximal** — destroys the one thing time built | none (this one strikes after death) | open licenses on code *and* data from day 1; plain forkable formats (parquet/CSV); **escrow snapshots with DOIs (e.g. Zenodo) at each release** (new, TODO X9) |
| F9 | **Legal surprise.** A provider objected to bulk redistribution of its series; takedown stress soured the fun | — | Low | Medium | bulk-mirroring a single provider's database without checking | per-source **license registry** (new, TODO X9); prefer derived series (forecasts, errors, scores) where rights are unclear ([06 §2](06-vintage-reconstruction.md)) |

## 2. The shape of the verdict

- **The most probable death is F1, and it is survivable.** The graveyard shows projects whose value outlived them (C5, C6) and projects whose value died with them (C1, C9). The difference was never popularity — it was whether dormancy and death were *designed for*. Every architectural choice already made (static-first, archive-first, thin deps, no standing services) is also the F1 countermeasure: a project that costs nothing at rest can hibernate through a lost year and resume.
- **The moat needs an heir.** F8 is the only maximal-damage row. One afternoon of escrow setup (open data license, DOI snapshots) converts "the archive dies with the repo" into "anyone can resurrect it" — the cheapest insurance in this document.
- **Credibility risks (F3, F5) are managed by honesty mechanisms, not by being right.** Self-announcing staleness, visible uncertainty, a decided target measure, and published own-errors make being wrong or being paused survivable; pretending otherwise made C8 a parable.

## 3. Sunset protocol (written now, while it costs nothing)

Modeled on the good deaths (C5: archive stays free and accessible; C6: announce, document replacements, thank people). If the project ends, deliberately or by neglect, the following hold:

1. The repo, data archive, and research docs remain public under open licenses; final state snapshotted with a DOI.
2. The dashboard switches to (or already shows) dormant-mode notice with the last-updated date — never silent staleness.
3. A short SUNSET note states what worked, what didn't, and where successors can find the archive and pick up — this repo's own contribution to the next builder's `07-graveyard` doc.
4. No data deletion, no private hoarding, no C9.

## 4. Changes triggered by this pre-mortem

Folded into [TODO](../TODO.md) as **X9** (fail-loud CI + dependency/license registers, staleness banner, no-SLA note, no-streak rule, Zenodo escrow, sunset note skeleton) and a design requirement on X5. Methodology debt note in [00](00-methodology-and-rubrics.md) updated: the negative-case sweep and pre-mortem are done; the rubric sensitivity check (X6 remainder) is still open.
