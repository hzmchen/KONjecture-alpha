# Demand: Potential Users, Requirements, and Open-Source Selling Points

**Research date:** 2026-06-10 · Quote tags [V]/[S] and source grades A–D per [00-methodology-and-rubrics.md](00-methodology-and-rubrics.md).

## 1. Is there demand for GDP nowcasts at all?

**Strong evidence (R5).** Four independent lines:

1. **People pay for it.** Now-Casting Economics: **[V]** "Our clients are primarily investment institutions – asset managers, hedge funds, and banks – who pay an annual subscription fee and receive our models' output data as a continuous feed." Consensus Economics sustains a subscription business polling **[S]** "more than 700 to 1000 economists each month" across up to 100 countries.
2. **Free offerings are heavily followed.** The Atlanta Fed positions GDPNow as filling a real need: **[V]** "GDPNow fills an important economic information gap. Users can access a real-time and empirically driven forecast of US GDP growth before official estimates are released. The frequent updates to the tool make it useful for economists, journalists, and anyone who wants to track broader economic shifts before the official reports and forecasts." Practitioner shorthand (grade D, colour): **[V]** "If you trade rates, manage macro risk, or just want to know what the U.S. economy is doing before the Bureau of Economic Analysis tells you, you've probably stared at the Atlanta Fed's GDPNow tracker." Commercial chart platforms (MacroMicro, Trading Economics, investing.com calendars) *republish* GDPNow/NY Fed numbers — third parties monetizing the aggregation gap.
3. **Institutions keep building new ones.** OECD (Weekly Tracker), Bundesbank (WAI), UNCTAD (weekly nowcasts), NY Fed (relaunch 2023), ESCoE (UK regions) — sustained public-sector investment post-2020. The BIS survey (grade A): **[S]** "around 80% of central banks discuss the topic of big data formally within their institution, up from 30% in 2015", and per the IFC/SUERF summary, **[S]** "A large and increasing number of central banks support their economic analyses with nowcasting models using big data … Preference for nowcasting exercises is particularly strong (40% of the cases reported interest)."
4. **When one disappears, a gap is felt.** The NY Fed nowcast was suspended for two full years (Sept 2021 → Sept 2023): **[V]** "The onset of the COVID-19 pandemic sparked widespread economic disruptions—and unprecedented fluctuations in the economic data … leading to the suspension of publication in September 2021." During the outage, market commentary tracked its absence (grade C/D sources). A community-maintained platform is resilient to any single institution's publication policy.

## 2. User segments

### S1 — Official sector: central banks, ministries, statistical offices
Need: cross-checking their own internal nowcasts, benchmarking, vintage-correct evaluation; institutional appetite for open tooling is documented — DBnomics is **[V]** "already used by analysts, data scientists, and modelers in major public institutions, including the OECD, Bank of France, and the French Directorate General of the Treasury." On open-sourcing models (BIS IFC, grade B): **[V]** "The advantages of open sourcing model code include enhanced predictability, accountability, streamlined collaboration eg with other central banks, improvements to the quality of the models and raised awareness about models," and **[V]** "Open-sourced macroeconomic models can be the next frontier in central bank communication."

### S2 — Financial-market professionals (macro analysts, asset managers, rates traders)
The proven paying segment (Now-Casting's clients [V]). Requirements: timeliness, machine-readable feed/API, reliability, breadth of countries. For an OSS project they are *users and amplifiers*, rarely contributors.

### S3 — Journalists and economic commentators
Named explicitly by the Atlanta Fed as a GDPNow audience [V]. Requirements: a single authoritative chart to embed/cite, plain-language uncertainty, comparison across forecasters ("who said what, who was right"), permissive reuse (open license) — something paywalled vendors cannot give them.

### S4 — Regional and sub-national policymakers/analysts
ESCoE (grade B): the service **[V]** "meets a key demand from stakeholders for more timely information on the performance of regional economies", and **[V]** "Timely and high-frequency regional macroeconomic indicators are essential for effective decision-making and supporting growth across the UK." Outside the UK this demand is unserved in open form (EU NUTS2 nowcasting exists only as a research paper, arXiv:2401.10054).

### S5 — Academic researchers and students (macroeconometrics, forecasting)
Requirements: benchmark datasets with vintages, a harness to enter a new model and get comparable scores, citability. Direct precedent that researchers *join* such platforms: the COVID-19 Forecast Hub collected forecasts from **[S]** "over 40 international research teams from academia and industry" (Zoltar paper, arXiv:2006.03922); the hubverse today is **[S]** "used by nearly two dozen collaborative and local modeling hubs around the globe." Economics is also institutionally pushing reproducibility: **[S]** the World Bank "introduced a strict reproducibility requirement" for its working papers, and AEA/RES journals "require a so-called 'replication package' as part of the submission." Highest *contribution* potential of all segments.

### S6 — International organisations & forecast watchdogs
IMF/OECD/EC forecast accuracy is a recurring research and accountability topic (grade A literature): **[S]** IMF WEO forecasts "have tended to be consistently over-optimistic in times of country-specific, regional, and global recessions"; **[S]** OECD post-crisis projections "mostly overestimated GDP growth, failed to anticipate the magnitude of the impact of the crisis." Today that scrutiny happens in one-off papers; a standing, reproducible evaluation platform would serve evaluators and the evaluated.

### S7 — General public
Large reach, shallow need; served as a by-product (free dashboard), not a design target.

## 3. Rubric R4 — segment scoring

Weights: reach .15, need intensity .30, evidence strength .25, OSS adoption .15, contribution potential .15 (see [rubrics](00-methodology-and-rubrics.md)).

| Segment | Reach | Need | Evidence | OSS | Contrib | **Score** | Tier |
|---|---|---|---|---|---|---|---|
| S2 Financial professionals | 4 | 5 | 5 | 3 | 2 | **4.10** | **1** |
| S5 Academics & students | 3 | 4 | 3 | 5 | 5 | **3.90** | 2 (high) |
| S1 Official sector | 3 | 4 | 4 | 4 | 4 | **3.85** | 2 (high) |
| S4 Regional policymakers | 3 | 5 | 4 | 2 | 2 | **3.55** | 2 |
| S3 Journalists | 3 | 4 | 4 | 3 | 1 | **3.25** | 2 |
| S6 IOs & watchdogs | 2 | 3 | 3 | 4 | 3 | **3.00** | 2 (low) |
| S7 General public | 5 | 2 | 2 | 2 | 1 | **2.30** | 3 |

**Interpretation.** Demand *pull* is strongest from finance (Tier 1), but an open-source project's early community will realistically be S5 + S1 (high OSS-adoption and contribution scores): academics supply models, official-sector economists supply credibility and use cases; finance and journalists then consume and amplify. This mirrors how the COVID Forecast Hub grew (academic teams → CDC adoption → media citation).

### v2 re-scoring under the Liebhaberei lens (P-A)

With the hobby weights from [00 §R4-v2](00-methodology-and-rubrics.md) (Reach .10, Need .20, Evidence .15, OSS .20, Contribution .35) the ranking inverts — segments are ranked by the energy they give back, not the pull they exert:

| Segment | v1 score (market pull) | v2 score (hobby) | v2 tier |
|---|---|---|---|
| **S0 The maintainer** | — | — | **Above all tiers by definition** ("scratch your own itch") |
| S5 Academics & students | 3.90 | **4.30** | **1** |
| S1 Official sector | 3.85 | 3.90 | 2 (high) |
| S2 Financial professionals | 4.10 | 3.45 | 2 |
| S6 IOs & watchdogs | 3.00 | 3.10 | 2 |
| S4 Regional policymakers | 3.55 | 3.00 | 2 (low) |
| S3 Journalists | 3.25 | 2.65 | 3 |
| S7 General public | 2.30 | 1.95 | 3 |

The v1 Tier-1 segment (finance) drops: its members want feeds, reliability, and support — pure maintenance load with near-zero contribution, the classic open-source burnout vector. The design target becomes: **a tool the maintainer enjoys using weekly, that an econometrics student could contribute a model to.** Everything else is a welcome by-product.

## 3a. Jobs-to-be-done (v2)

The segment view obscures that the evidence actually supports four *jobs* (Christensen/Ulwick framing); features should map to jobs, not personas:

| Job | "Hire" trigger | Today's imperfect hire | Evidence |
|---|---|---|---|
| J1 **Know now** — "where is the economy *right now*, before official data?" | data release, market move, news event | GDPNow page, NY Fed PDF, paywalled feeds | Strong (01 §2, 02 §1) |
| J2 **Compare** — "who says what, and why do they differ?" | conflicting headlines quoting different trackers | manual tab-hopping; MacroMicro charts | Strong (G1; Atlanta Fed refuses the job [V]) |
| J3 **Hold accountable** — "who has actually been right?" | post-mortem after a surprise; choosing whom to trust | one-off academic papers; FocusEconomics awards (paywalled) | Strong (G2; forecast-error literature) |
| J4 **Teach & benchmark** — "give students/papers a reproducible playground" | course design; referee asks for benchmark | ad-hoc replication code; FRED-MD | Moderate (S5 evidence; epi-hub precedent) |

J1 is well-served by incumbents; **J2 and J3 are the unserved jobs** and both are served by the *same* artifact: an archive of point-in-time forecasts plus a comparison view. J4 is the contribution on-ramp. This confirms the synthesis priority order independently of the segment scoring.

## 4. Requirements matrix

Requirements consolidated from the evidence above; ● = primary, ○ = secondary.

| Requirement | S1 | S2 | S3 | S4 | S5 | S6 |
|---|---|---|---|---|---|---|
| R-1 Timeliness (update on every release) | ● | ● | ● | ● | ○ | ○ |
| R-2 Multi-country + EU aggregate coverage | ● | ● | ○ | ○ | ● | ● |
| R-3 Sub-national coverage | ○ | ○ | ○ | ● | ○ | ○ |
| R-4 Uncertainty quantification (bands, densities) | ● | ● | ● | ○ | ● | ● |
| R-5 Side-by-side comparison of models & institutions | ● | ● | ● | ○ | ● | ● |
| R-6 Past-forecast review (expected vs realised) | ● | ○ | ● | ○ | ● | ● |
| R-7 Vintage-correct evaluation & leaderboard | ● | ○ | ○ | ○ | ● | ● |
| R-8 API / machine-readable data export | ● | ● | ○ | ○ | ● | ● |
| R-9 Transparent, reproducible methodology (open code) | ● | ○ | ○ | ○ | ● | ● |
| R-10 Zero cost / open license for reuse | ○ | ○ | ● | ● | ● | ○ |
| R-11 Extensibility: plug in own model / data | ● | ○ | — | ○ | ● | ○ |

Note R-5/R-6/R-7 — the *comparison and accountability* cluster — are exactly the components no existing macro offering provides (gaps G1–G3 in [01-supply](01-supply-existing-frameworks.md)).

## 5. Likely selling points (open source, not paid)

| # | Selling point | Grounding |
|---|---------------|-----------|
| P1 | **Free what is paywalled**: cross-country nowcast feed + institutional forecast comparison, today sold by Now-Casting/Consensus/FocusEconomics | [V]/[S], Strong |
| P2 | **Actually open**: GDPNow publishes methodology but not code — **[V]** "The methodology is open; the implementation is closed" (grade D, colour). KONjecture can be the first *fully* open, end-to-end GDP nowcast: data → code → outputs → evaluation. BIS: open-sourcing brings "enhanced predictability, accountability, streamlined collaboration" [V] | Strong |
| P3 | **The neutral comparison venue**: producers won't compare themselves — Atlanta Fed: **[V]** "Our policy is not to comment on or interpret any differences between the forecasts of these two models." A third party can, and chart aggregators prove the appetite | Strong |
| P4 | **Accountability leaderboard**: continuous, vintage-correct scoring of models *and* institutions; demanded by the forecast-error literature (S6), commercially validated by FocusEconomics awards, methodologically validated by hubverse/scoringutils in epidemiology | Strong |
| P5 | **Resilience/continuity**: not subject to one institution's publication decisions (NY Fed two-year suspension [V]) | Moderate |
| P6 | **Research platform**: standardized benchmark + harness lowers the cost of entering a new model from a paper; the hub model demonstrably attracts academic teams (40+ in COVID hub [S]) | Moderate–Strong |

**Anti-selling-points (honest constraints):** finance users want SLAs and support (OSS gives neither by default); journalists need editorial trust, which a young project lacks; official institutions adopt slowly. These shape the go-to-market in [03-synthesis](03-synthesis-market-gap-and-fit.md).

## References

| Ref | Source (grade) |
|---|---|
| 1 | [Now-Casting Economics — About](https://now-casting.com/about.html) (C) [V] |
| 2 | [Consensus Economics — Forecast surveys](https://www.consensuseconomics.com/forecast-surveys/) (C) [S] |
| 3 | [Atlanta Fed — GDPNow explainer](https://www.atlantafed.org/research-and-data/data/gdpnow/explainer) (B) [V] |
| 4 | [Medium — Inside GDPNow (Curry)](https://medium.com/@brian-curry-research/inside-gdpnow-a-complete-reverse-engineering-of-the-feds-most-watched-nowcast-adcfeaf0afe6) (D) [V] |
| 5 | [BIS Working Paper 930 — Big data and machine learning in central banking](https://www.bis.org/publ/work930.htm) (A) [V/S] |
| 6 | [SUERF — How do central banks use big data and machine learning?](https://www.suerf.org/publications/suerf-policy-notes-and-briefs/how-do-central-banks-use-big-data-and-machine-learning/) (B) [S] |
| 7 | [Liberty Street Economics — Reintroducing the NY Fed Staff Nowcast](https://libertystreeteconomics.newyorkfed.org/2023/09/reintroducing-the-new-york-fed-staff-nowcast/) (A/B) [V] |
| 8 | [DBnomics — About](https://db.nomics.world/about) (B) [V] |
| 9 | [Araujo (BIS IFC Bulletin 64) — Open-sourced central bank macroeconomic models](https://www.bis.org/ifc/publ/ifcb64_17_rh.pdf) (B) [V] |
| 10 | [ESCoE — Regional nowcasting in the UK](https://www.escoe.ac.uk/projects/regional-nowcasting-in-the-uk/) (B) [V] |
| 11 | [Reich et al. — Zoltar forecast archive, arXiv:2006.03922](https://arxiv.org/abs/2006.03922) (B) [S] |
| 12 | [Hubverse consortium paper, medRxiv 2025](https://www.medrxiv.org/content/10.1101/2025.10.03.25337284v1) (A) [S] |
| 13 | [BITSS — The World Bank's Reproducible Research Initiative](https://www.bitss.org/the-world-banks-reproducible-research-initiative-raising-the-bar-for-transparency-in-development-economics/) (B) [S] |
| 14 | [ZBW Open Economics Guide — How Research is Made Reproducible](https://openeconomics.zbw.eu/en/knowledgebase/how-research-is-made-reproducible/) (B) [S] |
| 15 | [Genberg & Martinez — On the Accuracy and Efficiency of IMF Forecasts](https://www.semanticscholar.org/paper/e33bd52691cd68a778df1eef459b68aa726ef9d4) (B) [S] |
| 16 | [Pons (2000) — The accuracy of IMF and OECD forecasts for G7 countries, J. Forecasting](https://onlinelibrary.wiley.com/doi/pdf/10.1002/\(SICI\)1099-131X\(200001\)19:1%3C53::AID-FOR736%3E3.0.CO;2-J) (A) [S] |
| 17 | [FocusEconomics — Awards methodology](https://www.focus-economics.com/best-economic-forecaster-awards/) (C) [S] |
| 18 | [Koop et al. — Nowcasting economic activity in European regions, arXiv:2401.10054](https://arxiv.org/pdf/2401.10054) (A) [S] |
