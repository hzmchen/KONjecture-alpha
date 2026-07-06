#!/usr/bin/env python3
"""Download raw upstream files into data/raw/ with a provenance manifest.

Polite by design: one GET per file, descriptive User-Agent, and existing
files are NOT re-downloaded unless --refresh is passed (append-only cache,
see docs/schema.md). No API keys are used; ALFRED (needs a key) is deferred
and documented in ingest/README.md.
"""

import argparse
import hashlib
import json
import sys
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "data" / "raw"
MANIFEST = RAW / "manifest.json"
UA = "KONjecture-alpha archive seeding (one-off bulk download; contact: news378@team706.com)"

SOURCES = {
    "gdpnow": {
        "url": "https://www.atlantafed.org/-/media/Project/Atlanta/FRBA/Documents/cqer/researchcq/gdpnow/GDPTrackingModelDataAndForecasts.xlsx",
        "file": "gdpnow_tracking.xlsx",
        "notes": "Atlanta Fed GDPNow: TrackingDeepArchives / TrackingArchives / TrackRecord tabs; TrackRecord includes BEA advance estimates (outcome vintage 'advance').",
    },
    "nyfed": {
        "url": "https://www.newyorkfed.org/medialibrary/Research/Interactives/Data/NowCast/Downloads/New-York-Fed-Staff-Nowcast_download_data.xlsx",
        "file": "nyfed_staff_nowcast.xlsx",
        "notes": "NY Fed Staff Nowcast historical data (2016-2021 era and 2023- relaunch).",
    },
    "spf_philly_meangrowth": {
        "url": "https://www.philadelphiafed.org/-/media/frbp/assets/surveys-and-data/survey-of-professional-forecasters/historical-data/meangrowth.xlsx",
        "file": "spf_philly_meangrowth.xlsx",
        "notes": "Philadelphia Fed SPF mean growth-rate forecasts (RGDP tab = SAAR q/q %, quarterly rounds since 1968).",
    },
    "fred_monthly": {
        "url": "https://fred.stlouisfed.org/graph/fredgraph.csv?id=INDPRO,PAYEMS,RSAFS,UNRATE,DGORDER",
        "file": "fred_monthly_indicators.csv",
        "notes": "N2 spike inputs: monthly US indicators (industrial production, payrolls, retail sales, unemployment, durable goods orders), latest vintage via keyless fredgraph endpoint. Vintage-correct pulls need ALFRED (deferred, API key).",
    },
    "fred_gdp": {
        "url": "https://fred.stlouisfed.org/graph/fredgraph.csv?id=A191RL1Q225SBEA",
        "file": "fred_gdp_growth.csv",
        "notes": "N2 spike target: US real GDP growth (SAAR %, quarterly, latest vintage).",
    },
    "spf_ecb": {
        "url": "https://www.ecb.europa.eu/stats/prices/indic/forecast/shared/files/SPF_individual_forecasts.zip",
        "file": "spf_ecb_individual.zip",
        "notes": "ECB SPF individual forecasts, all rounds since 1999Q1 (one CSV per round).",
    },
}


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--refresh", action="store_true", help="re-download even if cached")
    ap.add_argument("--only", nargs="*", help="subset of source ids")
    args = ap.parse_args()

    RAW.mkdir(parents=True, exist_ok=True)
    manifest = json.loads(MANIFEST.read_text()) if MANIFEST.exists() else {}
    failures = []

    for sid, src in SOURCES.items():
        if args.only and sid not in args.only:
            continue
        dest = RAW / src["file"]
        if dest.exists() and not args.refresh:
            print(f"[skip] {sid}: cached ({dest.name})")
            continue
        print(f"[get ] {sid}: {src['url']}")
        req = urllib.request.Request(src["url"], headers={"User-Agent": UA})
        try:
            with urllib.request.urlopen(req, timeout=120) as resp:
                data = resp.read()
        except Exception as e:  # noqa: BLE001 - report and continue with other sources
            print(f"[FAIL] {sid}: {e}", file=sys.stderr)
            failures.append(sid)
            continue
        dest.write_bytes(data)
        manifest[src["file"]] = {
            "source_id": sid,
            "url": src["url"],
            "retrieved_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
            "sha256": sha256(dest),
            "bytes": len(data),
            "notes": src["notes"],
        }
        print(f"[ ok ] {sid}: {len(data):,} bytes")

    MANIFEST.write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"manifest: {MANIFEST.relative_to(ROOT)} ({len(manifest)} files)")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
