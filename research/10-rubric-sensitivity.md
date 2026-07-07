# 10 — Rubric sensitivity check (X6)

**Date:** 2026-07-07 · **Method:** every feasible ±1 perturbation of a single R6 factor
(Unmet-ness ∈ 1–5, Demand tier weight ∈ {1,2,3}, Feasibility ∈ 1–5), one at a time, all else
fixed; reproducible via `Rscript research/10-rubric-sensitivity.R`. This discharges the
methodological caution recorded in [00 §R6](00-methodology-and-rubrics.md): *"rankings should
survive a ±1 perturbation of any single score before being acted on."* Base scores are the v2
values from [03 §2](03-synthesis-market-gap-and-fit.md) (G2 feasibility 4, G5 unmet-ness 3).

## Result

29 single-factor perturbations are feasible; 13 change the strict ordering or create a tie —
but **none moves any gap across an action-bucket boundary** (MVP → phase 2 → later → icebox):

| Question the ranking is used for | Verdict |
|---|---|
| G1 (comparison hub) is the MVP | **Robust.** G1 never drops below rank 1; the worst single perturbation (demand tier 3→2) leaves it tied with G2 at 40, never behind it. |
| G2/G3 both belong to the next phase | **Robust as a pair, fragile as an order.** Five different single perturbations swap G2 ↔ G3 (e.g. G2 feasibility −1 → 30 < 36; G3 feasibility +1 → 48 > 40). The v2 claim "G2 ≈ 40, closing on G3" should be read as *G2 and G3 are indistinguishable at this rubric's resolution* — not as G2 > G3. |
| G4/G5 are "later" | **Robust as a pair, fragile as an order** (four swaps, e.g. G5 feasibility +1 → 18 > 16). Same reading: an unordered tier. |
| G7 is not roadmap | **Robust.** Max single perturbation reaches 10, still last by a wide margin. |

## Consequences

1. **No build-order change.** Every decision actually taken so far leans only on the bucket
   membership, which is perturbation-stable — the strict ranks were never load-bearing.
2. **Recorded reading rule:** within a bucket, treat gaps as unordered. Any future decision that
   needs G2 > G3 (or G4 > G5) to be true must find evidence outside R6.
3. Ties under perturbation (G1/G2 at 40, G4/G5 at 12/16) reinforce the [00 §R6] framing:
   screening ranks, not magnitudes.

X6's remaining scope (the negative-case sweep and pre-mortem) was already discharged in
[07](07-graveyard-negative-cases.md) and [08](08-pre-mortem.md).
