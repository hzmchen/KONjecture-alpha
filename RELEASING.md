# Releasing (with escrow)

Event-driven cadence — releases happen when something is worth releasing, never on a
calendar promise (no-streak rule, [research/08 §4](research/08-pre-mortem.md)).

## Checklist

1. `cd pipeline && Rscript -e 'targets::tar_make()'` — everything green, outputs committed.
2. `Rscript tests/run_tests.R` and `Rscript tests/coverage.R` — record the numbers.
3. Regenerate the walkthrough: `bash walkthrough/build.sh && bash walkthrough/screenshots.sh`.
4. Tag: `git tag -a vX.Y -m "…"` — versions are milestones, not schedules.
5. **Escrow snapshot (Zenodo/DOI)** — the dependency-death insurance:
   - `git archive --format=zip -o konjecture-vX.Y.zip vX.Y`
   - upload the zip **plus** `data/archive/*.parquet` and `data/raw/manifest.json` to the
     Zenodo deposition (metadata in [.zenodo.json](.zenodo.json); first release creates the
     concept DOI, later ones version it);
   - record the DOI in the README and in the GitHub release notes.
6. GitHub release with a short, factual note (what changed, what the archive now covers).

Owner-held credentials required: Zenodo account/token. Until one exists, steps 5–6 are
pending owner action; the skeleton keeps the procedure explicit rather than aspirational.
