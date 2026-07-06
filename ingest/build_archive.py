#!/usr/bin/env python3
"""Build the normalized vintage-correct archive from data/raw/ (see docs/schema.md).

Reads only the local cache — no network. Emits data/archive/{forecasts,outcomes}
as parquet + csv mirror, append-only semantics: the build is deterministic from
the raw cache, so "appending" happens by refreshing the cache, not by editing
outputs. Every row carries provenance (source_file, retrieved_at).
"""

import io
import json
import re
import zipfile
from datetime import date
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "data" / "raw"
OUT = ROOT / "data" / "archive"
E = dict(engine="calamine")

MANIFEST = json.loads((RAW / "manifest.json").read_text())


def retrieved(fname: str) -> str:
    return MANIFEST[fname]["retrieved_at"]


def saar_to_qq(s: pd.Series) -> pd.Series:
    return ((1 + s / 100) ** 0.25 - 1) * 100


def quarter_label(d) -> str:
    d = pd.Timestamp(d)
    return f"{d.year}Q{d.quarter}"


# --- GDPNow: forecasts (TrackingDeepArchives + TrackingArchives) + outcomes (TrackRecord) ---

def gdpnow():
    f = "gdpnow_tracking.xlsx"
    frames = []
    for sheet in ["TrackingDeepArchives", "TrackingArchives"]:
        df = pd.read_excel(RAW / f, sheet_name=sheet, **E)
        df = df.rename(columns=lambda c: str(c).strip())
        keep = df[["Forecast Date", "Quarter being forecasted", "GDP Nowcast"]].dropna()
        keep = keep.assign(sheet=sheet)
        frames.append(keep)
    fc = pd.concat(frames, ignore_index=True)
    # overlap between the two tabs: keep the regular archive's row
    fc = fc.sort_values("sheet").drop_duplicates(
        subset=["Forecast Date", "Quarter being forecasted"], keep="last"
    )
    fc = pd.DataFrame({
        "source": "gdpnow",
        "region": "US",
        "variable": "rgdp_growth",
        "target_period": fc["Quarter being forecasted"].map(quarter_label),
        "forecast_date": pd.to_datetime(fc["Forecast Date"]).dt.date,
        "output_type": "point",
        "output_id": None,
        "value_native": fc["GDP Nowcast"].astype(float),
        "unit_native": "saar_pct",
        "declared_target": "advance",  # GDPNow TrackRecord scores itself vs BEA advance
        "retrieved_at": retrieved(f),
        "source_file": f,
    })

    tr = pd.read_excel(RAW / f, sheet_name="TrackRecord", skiprows=1, header=None, **E)
    tr = tr.iloc[:, [0, 2, 3]].dropna()
    oc = pd.DataFrame({
        "region": "US",
        "variable": "rgdp_growth",
        "target_period": tr[0].map(quarter_label),
        "release_label": "advance",
        "published_on": pd.to_datetime(tr[3]).dt.date,
        "value_native": tr[2].astype(float),
        "unit_native": "saar_pct",
        "source": "gdpnow_trackrecord(BEA)",
        "retrieved_at": retrieved(f),
        "source_file": f,
    })
    return fc, oc


def gdpnow_current():
    """In-flight quarter from CurrentQtrEvolution (not yet in the archive tabs):
    [Date, Major Releases, GDP*] column triplets; quarter parsed from the
    'Initial GDPNow YY:Qq forecast' label."""
    f = "gdpnow_tracking.xlsx"
    df = pd.read_excel(RAW / f, sheet_name="CurrentQtrEvolution", header=None, **E)
    m = None
    for cell in df.astype(str).to_numpy().ravel():
        mm = re.search(r"Initial GDPNow (\d\d):Q(\d) forecast", cell)
        if mm:
            m = mm
            break
    if not m:
        return pd.DataFrame()
    tp = f"20{m.group(1)}Q{m.group(2)}"
    rows = []
    for c in range(0, df.shape[1] - 2, 3):
        dates = pd.to_datetime(df[c], errors="coerce")
        vals = pd.to_numeric(df[c + 2], errors="coerce")
        ok = dates.notna() & vals.notna()
        rows.append(pd.DataFrame({"forecast_date": dates[ok].dt.date, "value": vals[ok]}))
    cur = pd.concat(rows, ignore_index=True).drop_duplicates(subset=["forecast_date"])
    return pd.DataFrame({
        "source": "gdpnow",
        "region": "US",
        "variable": "rgdp_growth",
        "target_period": tp,
        "forecast_date": cur["forecast_date"],
        "output_type": "point",
        "output_id": None,
        "value_native": cur["value"].astype(float),
        "unit_native": "saar_pct",
        "declared_target": "advance",
        "retrieved_at": retrieved(f),
        "source_file": f"{f}:CurrentQtrEvolution",
    })


# --- NY Fed Staff Nowcast: Forecasts By Quarter grid (2023- relaunch file) ---

def nyfed():
    f = "nyfed_staff_nowcast.xlsx"
    raw = pd.read_excel(RAW / f, sheet_name="Forecasts By Quarter", header=None, **E)
    hdr_idx = raw.index[raw[0].astype(str).str.strip() == "Forecast Date"][0]
    hdr = raw.iloc[hdr_idx]
    df = raw.iloc[hdr_idx + 1:].copy()
    df.columns = hdr
    df = df[pd.to_datetime(df["Forecast Date"], errors="coerce").notna()]
    qcols = [c for c in df.columns if re.fullmatch(r"\d{4}Q[1-4]", str(c))]
    long = df.melt(id_vars=["Forecast Date"], value_vars=qcols,
                   var_name="target_period", value_name="value").dropna(subset=["value"])
    return pd.DataFrame({
        "source": "nyfed",
        "region": "US",
        "variable": "rgdp_growth",
        "target_period": long["target_period"].astype(str),
        "forecast_date": pd.to_datetime(long["Forecast Date"]).dt.date,
        "output_type": "point",
        "output_id": None,
        "value_native": long["value"].astype(float),
        "unit_native": "saar_pct",
        "declared_target": "unspecified",
        "retrieved_at": retrieved(f),
        "source_file": f,
    })


# --- Philadelphia Fed SPF: mean current-quarter growth (drgdp2) per survey round ---

PHILLY_ROUND_MONTH = {1: 2, 2: 5, 3: 8, 4: 11}  # survey published mid Feb/May/Aug/Nov


def spf_philly():
    f = "spf_philly_meangrowth.xlsx"
    df = pd.read_excel(RAW / f, sheet_name="RGDP", **E).dropna(subset=["drgdp2"])
    # drgdp2 = mean forecast for the survey's own quarter (the SPF "nowcast"), SAAR %.
    # Exact deadline dates aren't in this file: forecast_date is approximated as the
    # 15th of the round's middle month (documented in ingest/README.md).
    return pd.DataFrame({
        "source": "spf_philly",
        "region": "US",
        "variable": "rgdp_growth",
        "target_period": df["YEAR"].astype(int).astype(str) + "Q" + df["QUARTER"].astype(int).astype(str),
        "forecast_date": [date(int(y), PHILLY_ROUND_MONTH[int(q)], 15)
                          for y, q in zip(df["YEAR"], df["QUARTER"])],
        "output_type": "point",
        "output_id": None,
        "value_native": df["drgdp2"].astype(float),
        "unit_native": "saar_pct",
        "declared_target": "unspecified",
        "retrieved_at": retrieved(f),
        "source_file": f,
    })


# --- ECB SPF: mean GDP point forecast per round & target (year-on-year, kept native) ---

GDP_HDR = "GROWTH EXPECTATIONS"


def spf_ecb():
    f = "spf_ecb_individual.zip"
    rows = []
    with zipfile.ZipFile(RAW / f) as z:
        for name in sorted(z.namelist()):
            m = re.fullmatch(r"(\d{4})Q([1-4])\.csv", name)
            if not m:
                continue
            year, q = int(m.group(1)), int(m.group(2))
            txt = z.read(name).decode("utf-8", errors="replace")
            df = pd.read_csv(io.StringIO(txt), header=None, dtype=str, engine="python",
                             on_bad_lines="skip")
            col0 = df[0].fillna("")
            # section headers = prose rows (letters, not TARGET_PERIOD); data rows start
            # with a target period like "2026", "2026Q4", "2027Mar"
            is_hdr = col0.str.contains(r"[A-Za-z]") & (col0 != "TARGET_PERIOD") & \
                ~col0.str.fullmatch(r"\d{4}(Q[1-4]|[A-Z][a-z]{2})?")
            hdr_idx = list(col0[is_hdr].index)
            gdp_start = [i for i in hdr_idx if GDP_HDR in col0[i]]
            if not gdp_start:
                continue
            start = gdp_start[0]
            later = [i for i in hdr_idx if i > start]
            end = later[0] if later else len(df)
            sec = df.iloc[start + 1:end]
            hdr_row = sec[sec[0] == "TARGET_PERIOD"]
            if hdr_row.empty:
                continue
            hdr = hdr_row.iloc[0]
            point_col = hdr[hdr == "POINT"].index[0]
            body = sec.loc[hdr_row.index[0] + 1:]
            body = body[body[0].notna() & (body[0] != "")]
            vals = pd.to_numeric(body[point_col], errors="coerce")
            grp = pd.DataFrame({"target": body[0], "point": vals}).dropna()
            for target, mean in grp.groupby("target")["point"].mean().items():
                rows.append({
                    "source": "spf_ecb",
                    "region": "EA",
                    "variable": "rgdp_growth",
                    "target_period": str(target),
                    # ECB SPF rounds close in the first month of the quarter (approx: 15th)
                    "forecast_date": date(year, (q - 1) * 3 + 1, 15),
                    "output_type": "point",
                    "output_id": None,
                    "value_native": round(float(mean), 4),
                    "unit_native": "yoy_pct",
                    "declared_target": "unspecified",
                    "retrieved_at": retrieved(f),
                    "source_file": f"{f}:{name}",
                })
    return pd.DataFrame(rows)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    gd_fc, gd_oc = gdpnow()
    gd_cur = gdpnow_current()
    if len(gd_cur):
        gd_fc = pd.concat([gd_fc, gd_cur], ignore_index=True).drop_duplicates(
            subset=["target_period", "forecast_date"], keep="first")
    forecasts = pd.concat([gd_fc, nyfed(), spf_philly(), spf_ecb()], ignore_index=True)
    forecasts["value_qq"] = forecasts["value_native"].where(
        forecasts["unit_native"] == "saar_pct").pipe(saar_to_qq).round(4)
    # yoy rows are not identifiable to q/q -> value_qq stays NaN by construction

    outcomes = gd_oc.copy()
    outcomes["value_qq"] = saar_to_qq(outcomes["value_native"]).round(4)

    col_order_fc = ["source", "region", "variable", "target_period", "forecast_date",
                    "output_type", "output_id", "value_native", "unit_native", "value_qq",
                    "declared_target", "retrieved_at", "source_file"]
    col_order_oc = ["region", "variable", "target_period", "release_label", "published_on",
                    "value_native", "unit_native", "value_qq", "source", "retrieved_at",
                    "source_file"]
    forecasts = forecasts[col_order_fc].sort_values(
        ["source", "target_period", "forecast_date"]).reset_index(drop=True)
    outcomes = outcomes[col_order_oc].sort_values(["target_period"]).reset_index(drop=True)

    for name, df in [("forecasts", forecasts), ("outcomes", outcomes)]:
        df.to_parquet(OUT / f"{name}.parquet", index=False)
        df.to_csv(OUT / f"{name}.csv", index=False)
        print(f"{name}: {len(df):,} rows -> data/archive/{name}.parquet (+.csv)")
    print("\nforecast rows per source:")
    print(forecasts.groupby("source").agg(rows=("value_native", "size"),
                                          first=("forecast_date", "min"),
                                          last=("forecast_date", "max")).to_string())


if __name__ == "__main__":
    main()
