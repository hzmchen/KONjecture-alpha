# X6: sensitivity check of the R6 gap-opportunity scores (research/00 §"Methodological
# caution"): the acted-on ranking must survive a ±1 perturbation of any single factor.
# Run: Rscript research/10-rubric-sensitivity.R   (writes nothing; output pasted into
# research/10-rubric-sensitivity.md)
#
# Factors per gap: Unmet-ness U in 1..5, Demand tier weight D in {1,2,3} (R4 tier),
# Feasibility F in 1..5. Score = U*D*F. v2 values (research/03 §2 + v2 revision).

gaps <- data.frame(
  gap = c("G1", "G2", "G3", "G4", "G5", "G7"),
  U   = c(5, 5, 4, 4, 3, 5),
  D   = c(3, 2, 3, 2, 2, 1),
  F   = c(4, 4, 3, 2, 2, 1)
)
gaps$score <- gaps$U * gaps$D * gaps$F
base_rank <- gaps$gap[order(-gaps$score)]

clamp <- function(x, lo, hi) pmin(hi, pmax(lo, x))
bounds <- list(U = c(1, 5), D = c(1, 3), F = c(1, 5))

cat("Base scores:\n")
print(gaps[order(-gaps$score), ], row.names = FALSE)
cat("\nBase ranking:", paste(base_rank, collapse = " > "), "\n\n")

# every single-factor +/-1 perturbation (one at a time, all else fixed)
cat(sprintf("%-4s %-7s %-4s %6s  %-30s %s\n",
            "gap", "factor", "d", "score", "ranking after perturbation", "order change?"))
n_pert <- 0; n_flip <- 0; flips <- character()
for (i in seq_len(nrow(gaps))) for (f in c("U", "D", "F")) for (d in c(-1, 1)) {
  v <- clamp(gaps[[f]][i] + d, bounds[[f]][1], bounds[[f]][2])
  if (v == gaps[[f]][i]) next  # perturbation clipped away at the bound
  g <- gaps; g[[f]][i] <- v
  g$score <- g$U * g$D * g$F
  new_rank <- g$gap[order(-g$score)]
  ties <- any(duplicated(g$score))
  changed <- !identical(new_rank, base_rank) || ties
  n_pert <- n_pert + 1
  if (changed) {
    n_flip <- n_flip + 1
    flips <- c(flips, sprintf("%s %s%+d -> %d: %s%s", gaps$gap[i], f, d, g$score[i],
                              paste(new_rank, collapse = " > "),
                              if (ties) "  [tie]" else ""))
  }
  cat(sprintf("%-4s %-7s %+d %6d  %-30s %s\n", gaps$gap[i], f, d, g$score[i],
              paste(new_rank, collapse = ">"),
              if (changed) if (ties) "TIE" else "FLIP" else ""))
}
cat(sprintf("\n%d perturbations feasible, %d change the strict ranking or create ties:\n", n_pert, n_flip))
cat(paste0("  ", flips, collapse = "\n"), "\n")

# the decision-relevant grouping, not the strict order: does any single
# perturbation move a gap across an action-bucket boundary?
buckets <- c(G1 = "mvp", G2 = "phase2", G3 = "phase2", G4 = "later", G5 = "later", G7 = "icebox")
cat("\nBucket-boundary check (mvp > phase2 > later > icebox):\n")
crossings <- 0
for (i in seq_len(nrow(gaps))) for (f in c("U", "D", "F")) for (d in c(-1, 1)) {
  v <- clamp(gaps[[f]][i] + d, bounds[[f]][1], bounds[[f]][2])
  if (v == gaps[[f]][i]) next
  g <- gaps; g[[f]][i] <- v
  g$score <- g$U * g$D * g$F
  # a crossing = some gap in a lower bucket now strictly outscores one in a higher bucket
  ord <- c(mvp = 4, phase2 = 3, later = 2, icebox = 1)[buckets[g$gap]]
  for (a in seq_len(nrow(g))) for (b in seq_len(nrow(g))) {
    if (ord[a] < ord[b] && g$score[a] > g$score[b]) {
      crossings <- crossings + 1
      cat(sprintf("  %s %s%+d: %s (%d, %s) outscores %s (%d, %s)\n",
                  gaps$gap[i], f, d, g$gap[a], g$score[a], buckets[g$gap[a]],
                  g$gap[b], g$score[b], buckets[g$gap[b]]))
    }
  }
}
if (crossings == 0) cat("  none — no single ±1 perturbation moves any gap across an action bucket\n")
