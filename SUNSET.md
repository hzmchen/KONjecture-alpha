# Sunset note (skeleton — activate when the project winds down)

Per the pre-mortem protocol ([research/08 §4](research/08-pre-mortem.md)): this project is
a one-person Liebhaberei and is *designed* to be able to stop gracefully. Dormancy is not
failure — pages announce their own staleness — but if development ends for good, this file
becomes the top-level notice.

## When activating, fill in and link from README:

- **Status:** retired as of `YYYY-MM-DD`. No further data updates; everything below stays
  reproducible from the committed raw cache.
- **What still works:** the static pages (`site/`), the archive (`data/archive/`), and
  `targets::tar_make()` against the pinned `renv.lock`.
- **Last escrow snapshot:** Zenodo DOI `10.5281/zenodo.XXXXXXX` (code + data archive as of
  the final release — see [RELEASING.md](RELEASING.md)).
- **Data reuse:** see the per-source licensing register in
  [ingest/README.md](ingest/README.md); derived tables in `data/archive/` are compilations
  of published statistics and forecasts.
- **Adopting the project:** fork freely (open license); the walkthrough
  ([walkthrough/](walkthrough/README.md)) is the onboarding document. No handover
  obligations exist or are implied.

## Sunset checklist

1. Final `tar_make()`, tests green, coverage recorded.
2. Final release per [RELEASING.md](RELEASING.md) incl. Zenodo escrow.
3. Fill in this note; link it from the README header; set the pages' dormant banner text
   to point here.
4. Archive the GitHub repo (read-only) — do not delete.
