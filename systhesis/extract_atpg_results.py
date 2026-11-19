#!/usr/bin/env python3
from pathlib import Path
import csv
import re

BASE = Path("results")
BASE_CSV = Path("results_summary.csv")
OUT = Path("results_final.csv")

coverage_re = re.compile(
    r"TDA-220\).*?:\s*"
    r"(?P<sim>\d+)\s+"
    r"(?P<eff>\d+)\s+"
    r"(?P<det>\d+)\s+"
    r"(?P<atcov>[0-9.]+)%\s+"
    r"(?P<global>[0-9.]+)%\s+"
    r"(?P<untested>\d+)"
)

def parse_atpg(log_path: Path):
    if not log_path.exists():
        return None
    matches = []
    for line in log_path.read_text(errors="ignore").splitlines():
        m = coverage_re.search(line)
        if m:
            matches.append(m.groupdict())
    if not matches:
        return None
    d = matches[-1]
    return {
        "ATPG_Sim_Tests": int(d["sim"]),
        "ATPG_Effective_Tests": int(d["eff"]),
        "ATPG_Coverage_%": float(d["atcov"]),
        "Global_Coverage_%": float(d["global"]),
        "Untested_Faults": int(d["untested"]),
    }

if not BASE_CSV.exists():
    raise SystemExit("ERRO: results_summary.csv nao encontrado. Rode primeiro: python3 extract_results.py")

with BASE_CSV.open(newline="") as f:
    base_rows = list(csv.DictReader(f))

final_rows = []
for row in base_rows:
    tag = f"DATA_W{row['DATA_W']}_DEPTH{row['DEPTH']}_WMAX{row['WMAX']}"
    atpg = parse_atpg(BASE / tag / "atpg_console.log")
    newrow = dict(row)
    if atpg:
        newrow.update(atpg)
    else:
        newrow.update({
            "ATPG_Sim_Tests": "",
            "ATPG_Effective_Tests": "",
            "ATPG_Coverage_%": "",
            "Global_Coverage_%": "",
            "Untested_Faults": "",
        })
    final_rows.append(newrow)

fields = list(final_rows[0].keys())
with OUT.open("w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=fields)
    w.writeheader()
    w.writerows(final_rows)

print()
print(f"{'DATA_W':>7} {'DEPTH':>7} {'WMAX':>7} {'SCAN':>7} {'AREA_PRE':>11} {'AREA_POST':>11} {'ATCOV':>9} {'GLOBAL':>9} {'UNTEST':>8}")
print("-" * 94)
for r in final_rows:
    cov = r.get("ATPG_Coverage_%", "")
    glob = r.get("Global_Coverage_%", "")
    unt = r.get("Untested_Faults", "")
    covs = f"{float(cov):.2f}%" if cov != "" else "-"
    globs = f"{float(glob):.2f}%" if glob != "" else "-"
    print(
        f"{r['DATA_W']:>7} {r['DEPTH']:>7} {r['WMAX']:>7} "
        f"{r['Scan_Registers']:>7} {float(r['Area_Pre']):>11.3f} {float(r['Area_Post']):>11.3f} "
        f"{covs:>9} {globs:>9} {str(unt):>8}"
    )

print()
print(f"Arquivo final gerado: {OUT}")
