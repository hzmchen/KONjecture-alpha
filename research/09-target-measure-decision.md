# Target Measure (N1 / Issue #2): Decision Analysis

**Analysis date:** 2026-07-06 · Addresses [Issue #2](https://github.com/hzmchen/KONjecture-alpha/issues/2) and [TODO N1](../TODO.md) · Inputs: [06 §2](06-vintage-reconstruction.md) (vintage availability, GDPNow precedent), [03 §5](03-synthesis-market-gap-and-fit.md) (archive as moat, C5/C6), [08 F3](08-pre-mortem.md) (self-announcing artifacts).

**Nature of this doc:** critical analysis of an internal decision, not new external research — no new sources; all claims trace to prior docs or to the issue text. Final say on Issue #2 rests with the project owner; this doc narrows the decision and recommends defaults.

## 1. Finding: N1 as originally framed was mostly already decided

N1 was listed as a blocker for archive schema design ("first publication vs final/latest vintage"). But [06 §2](06-vintage-reconstruction.md) already concludes the schema should **store the outcome as-of-vintage and make the headline target a presentation choice** — and the reconstructed archives (ALFRED, Gerda, ECB RTD) contain *all* outcome vintages anyway. Once every outcome vintage is stored:

- the **schema** no longer depends on the target choice at all;
- any target (first print, fixed-horizon, latest) is **recomputable retroactively**, so the defaults are reversible decisions;
- the genuinely blocking part of N1 — "record which vintage a score was computed against" — is settled in substance.

Consequently the binary in the issue title ("first vs final") is a false dilemma; **option 4** of Issue #2 (store all, score against several, headline as presentation) dominates the other three and is adopted here as the working recommendation. What remains open is a set of smaller, harder sub-decisions (§3).

**TODO impact:** N1 stops gating N2–N4. The schema rule for N2/N4 is fixed now: *every archived outcome row carries its own publication vintage; scores are (forecast, outcome-vintage-rule) pairs, never bare numbers.* Only X2 (scoring defaults) still waits on §3.

## 2. Recommended defaults (per Issue #2 option 4)

| Role | Target | Rationale |
|------|--------|-----------|
| **Headline (user-facing)** | First publication (advance/flash) | Matches user expectation ("what will be announced"), GDPNow TrackRecord precedent [06 §2], available ~30 days after quarter end |
| **Scientific (leaderboard)** | Fixed-horizon vintage (value as published *k* quarters after the reference quarter) | Stable, reproducible, standard in the real-time literature; avoids the moving-target problem of "latest vintage" |
| **Not a default** | Latest available vintage | Scores silently change as revisions arrive — hostile to a dormancy-tolerant project whose published artifacts must stay self-consistent while unattended ([08 F3](08-pre-mortem.md)) |

## 3. Remaining open sub-decisions (the real content of N1)

| ID | Decision | Why it is not trivial | Needed by |
|----|----------|----------------------|-----------|
| **D1** | **Per-region operationalization of "first publication."** US: advance vs second vs third estimate. Euro area: preliminary flash (t+30) vs flash (t+45) vs full first release (t+65). Others vary. | "First print" noisiness and timing differ by region, so a cross-region leaderboard against "first publication" compares **differently noisy targets**. Disclosure per region is required (extends the per-region degradation disclosure already mandated in [06 §2](06-vintage-reconstruction.md) to *target-noise heterogeneity*). | X2 (first backtest) |
| **D2** | **Choice of *k* for the fixed horizon.** Literature convention is ~2–3 years; it is a convention, not a derivation. | Any k still crosses benchmark revisions and definitional breaks (ESA95→ESA2010, chain-linking, base-year switches) — the harmonization risks [06 §2] lists for *inputs* apply to the *outcome* too. Growth rates mitigate, don't eliminate. Also: larger k = longer wait before recent quarters are scorable (see D4). | X2 |
| **D3** | **Units harmonization.** US SAAR (annualized q/q) vs European non-annualized q/q growth. | A target-measure question in all but name; absent from Issue #2. Recommendation: store non-annualized q/q as canonical, present SAAR as a display transform for US audiences. | N4 schema conventions |
| **D4** | **Dual-ranking presentation.** The two defaults don't just disagree in values — they **cover different time windows**: fixed-horizon scores are unavailable for the most recent k quarters, exactly the rows users care about most. | Two divergent rankings are a communication liability for a project committed to self-explaining artifacts ([08 F3]). Needs an explicit design answer (e.g. one table, "first-print score" always shown, "settled score (k=…)" filled in as it matures, blank cells labelled "settles in Q…"). | X5 (dashboard) |

## 4. Fairness caveats (feeds L1, not blocking now)

1. **Institutions target different vintages by construction.** GDPNow explicitly models the BEA advance estimate [06 §2]; other producers arguably track a smoothed latent concept. Scoring all against one vintage systematically favors whoever targets it. Option 4's multiple targets mitigate but do not remove this; L1's "fairness rules" must state per-track what each producer declares (or evidently intends) as its target.
2. **Multiple rankings invite cherry-picking** ("#1 on *some* target"). Countermeasure: fixed, pre-declared default per view; alternative targets one click away but never the landing view.
3. **Target-noise heterogeneity across regions** (D1) means cross-region score aggregation is not meaningful; the leaderboard should rank within region, never across.

## 5. Resulting TODO changes

- **N1** reworded: option-4 adoption recommended and treated as working assumption; remaining scope = D1–D4; no longer described as blocking the archive schema.
- **X2** trigger refined: needs **D1 + D2 decided** and N4 done (was: "N1 decided, N4 done").
- **X5** gains D4 as an input alongside the existing 08-F3 staleness requirement.
- **L1** gains §4 as an explicit input on fairness rules.

**Status (updated 2026-07-06): option 4 confirmed by the project owner — N1 is decided.** The recommendations in §2 are now the project's defaults. Residual work: D1–D2 must be fixed before X2 (both are cheap to decide once the first two institutional tracks — GDPNow, NY Fed, N4 step 1 — are ingested and their declared targets are visible in the data); D3 applies from the first N4 ingest; D4 is an X5 design input. Issue #2 can be closed referencing this doc.
