# Data-Access Clients (C2 regions, C4 institutional forecasts, C6 vintage inputs)

**Verified 2026-06-10** from CRAN/GitHub/DBnomics API ([method](README.md)). Scope: software clients for the data sources inventoried in [06-vintage-reconstruction](../06-vintage-reconstruction.md) and [01 §6](../01-supply-existing-frameworks.md). Direct-file sources (GDPNow xlsx, NY Fed xlsx, SPF CSVs, WEO archives) need only `readxl`/`data.table` and are not separately cataloged.

## 1. Primary multi-provider layer

| Component | Capabilities | Status [V] | License [V] | Availability | Verdict |
|---|---|---|---|---|---|
| **DBnomics platform + API** | Aggregates **93 providers** (live API count, 2026-06-10 [V]) — Eurostat, ECB, OECD, IMF, BIS, national institutes — behind one API; institutionally funded (<€200k/yr, used by OECD/Banque de France, [01 §6](../01-supply-existing-frameworks.md)) | live, active | open platform; **data licensing remains per original provider** | `api.db.nomics.world` (HTTP/JSON, SDMX ids) | **Adopt** as primary multi-country ingestion |
| `rdbnomics` (R client) | Fetch any DBnomics series into data.table | 0.6.4, 2020-10-25 — **stale on CRAN (5½ y)** but the v22 API it wraps is stable | **AGPL-3** | CRAN | Adopt **with eyes open**: AGPL copyleft + staleness. Fallback is trivial under P-B: the JSON API is simple enough to call directly with `httr2`, removing both concerns |

## 2. US (FRED/ALFRED — series + vintages)

| Component | Capabilities | Status [V] | License [V] | Availability | Verdict |
|---|---|---|---|---|---|
| `fredr` | Full FRED API client (series, releases, tags); ALFRED vintages via `realtime_start/end` | 2.1.0, 2021-01-29 — CRAN stale; GitHub last push 2023-04 | MIT | CRAN | Adopt w/ caution: thin wrapper over a very stable API; rebuildable in an afternoon if it rots. Requires free API key |
| `alfred` | Purpose-built: "real-time and vintage data from ALFRED" [S] | 0.2.1, 2023-03-21 | MIT | CRAN | Adopt for vintage pulls (N4); same caveat as `fredr` |

## 3. Euro area / EU / Germany

| Component | Capabilities | Status [V] | License [V] | Availability | Verdict |
|---|---|---|---|---|---|
| `eurostat` (rOpenSci) | Search/download Eurostat data incl. flash estimates; caching | 4.0.0, 2023-12-19 | BSD-2 | CRAN | **Adopt** for Eurostat |
| `ecb` | ECB Data Portal (SDW) client — covers ECB RTD vintage dataset access | 0.4.3, 2025-03-19 | CC0 | CRAN | **Adopt** for ECB incl. RTD |
| `bbk` | Modern client for **Bundesbank and ECB** data APIs | 0.10.0, 2026-05-16 — fresh, active | MIT | CRAN | **Adopt** for Bundesbank (incl. Gerda real-time series where exposed via API) |
| `bundesbank` | Minimal Bundesbank time-series downloader (single author, E. Schumann) | 0.1-12, 2024-04-19 | GPL-3 | CRAN | Alternative to `bbk`; keep whichever proves more robust for Gerda |
| `restatis` | Destatis GENESIS / regional / Zensus APIs | 0.4.1, 2026-06-01 — fresh | MIT | CRAN | Adopt if German source data needed beyond Bundesbank/Eurostat |
| ~~`wiesbaden`~~ | (was: Destatis client) | **[V] "Archived on 2025-07-21 at the maintainer's request"** | — | CRAN archive | Do not depend; `restatis` is the live successor. Graveyard data point for [07](../07-graveyard-negative-cases.md) |

## 4. International organisations & UK

| Component | Capabilities | Status [V] | License [V] | Availability | Verdict |
|---|---|---|---|---|---|
| `OECD` | OECD data API client | 0.2.5, 2021-12-01 — CRAN stale; GitHub push 2025-08 | CC0 | CRAN | **Caution:** OECD migrated to the Data Explorer SDMX API; verify the package against current endpoints before relying — else use `rsdmx`/DBnomics |
| `imf.data` | IMF data API client | 0.1.7, 2024-09-14 | MIT | CRAN | Optional (WEO vintages come as downloadable databases anyway, [06 §1b](../06-vintage-reconstruction.md)); verify against IMF's current API generation |
| `rsdmx` | Generic SDMX-ML consumer — works against any SDMX provider (ECB, Eurostat, OECD, IMF, BIS) | 0.6-5, 2025-02-27 | GPL-2\|3 | CRAN | **Adopt as universal fallback** when a bespoke client rots |
| `readsdmx` (OECD-authored) | Fast SDMX-ML → data.frame | 0.3.1, 2023-09-02 | GPL-3 | CRAN | Alternative SDMX parser; optional |
| `onsr` | UK ONS "Beta" API client | 1.0.2, 2023-12-21 | GPL-3 | CRAN | Include for X4 (UK region); verify before use |

## 5. Layer assessment

- **Dominant risk: provider-API churn, not code quality.** Three of the four stale/dead entries above (`OECD`, `wiesbaden`→`restatis`, `imf.data` caveat) trace to providers replacing their API generation. Clients here are *thin glue* in the [03 §5](../03-synthesis-market-gap-and-fit.md) taxonomy: prefer DBnomics + generic SDMX as the stable abstraction, treat per-provider packages as replaceable convenience, and let the fail-loud CI ([08 §4](../08-pre-mortem.md)) catch breakage.
- **Licensing of the *clients* is unproblematic** (mostly MIT/CC0/BSD) with one flag: `rdbnomics` AGPL-3 ([README §headline 5](README.md)). Licensing of the *data* is per provider and matters only at bulk-redistribution time ([06 §2 Legal](../06-vintage-reconstruction.md)).
- **API keys:** FRED/ALFRED require a free key (CI secret); DBnomics, ECB, Bundesbank, Eurostat are keyless — keyless sources fit dormancy better (no credential expiry on wake-up).

## References

CRAN canonical pages for every package above (`https://cran.r-project.org/package=<name>`), fetched 2026-06-10 [V]; [DBnomics providers API](https://api.db.nomics.world/v22/providers) [V]; GitHub repos: [sboysel/fredr](https://github.com/sboysel/fredr), [expersso/OECD](https://github.com/expersso/OECD) [V].
