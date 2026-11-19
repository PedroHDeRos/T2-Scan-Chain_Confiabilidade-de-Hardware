#!/usr/bin/env python3
from pathlib import Path
import csv
import re

BASE = Path("results")

def extract_params(folder_name):
    m = re.fullmatch(r"DATA_W(\d+)_DEPTH(\d+)_WMAX(\d+)", folder_name)
    if not m:
        return None
    return tuple(map(int, m.groups()))

def parse_area(path):
    text = path.read_text(errors="ignore")
    for line in reversed(text.splitlines()):
        if "stream_merge" in line:
            nums = re.findall(r"[-+]?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?", line)
            # O primeiro numero pode vir do nome do modulo (DATA_W16 etc.),
            # entao usamos os quatro ultimos: Cell Count, Cell Area, Net Area, Total Area.
            if len(nums) >= 4:
                cell_count = int(float(nums[-4]))
                cell_area = float(nums[-3])
                net_area = float(nums[-2])
                total_area = float(nums[-1])
                return cell_count, cell_area, net_area, total_area
    return None, None, None, None

def parse_power(path):
    text = path.read_text(errors="ignore")
    # No report_power do Genus, a linha Subtotal contem:
    # Leakage, Internal, Switching e Total.
    for line in text.splitlines():
        if "Subtotal" in line:
            nums = re.findall(r"[-+]?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?", line)
            if len(nums) >= 4:
                return float(nums[3])
    # Fallback para formatos diferentes
    for line in reversed(text.splitlines()):
        if re.search(r"\bTotal\b", line, re.IGNORECASE):
            nums = re.findall(r"[-+]?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?", line)
            if nums:
                return float(nums[-1])
    return None

def parse_scan(path):
    text = path.read_text(errors="ignore")
    lengths = [int(x) for x in re.findall(r"length:\s*(\d+)", text, flags=re.IGNORECASE)]
    chain_names = re.findall(r"Chain\s+\d+\s*:", text, flags=re.IGNORECASE)
    if not chain_names:
        chain_names = re.findall(r"AutoChain_\d+", text)
    chain_count = len(set(chain_names))
    return chain_count, sum(lengths) if lengths else None

rows = []

for folder in sorted(BASE.iterdir()):
    if not folder.is_dir():
        continue

    params = extract_params(folder.name)
    if not params:
        continue

    data_w, depth, wmax = params

    pre_cc, pre_ca, pre_na, pre_ta = parse_area(folder / "area_pre_dft.rpt")
    post_cc, post_ca, post_na, post_ta = parse_area(folder / "area_post_dft.rpt")

    p_pre = parse_power(folder / "power_pre_dft.rpt")
    p_post = parse_power(folder / "power_post_dft.rpt")

    chains, scan_regs = parse_scan(folder / "scan_chains.rpt")

    area_overhead = ((post_ta - pre_ta) / pre_ta * 100) if pre_ta and post_ta else None
    power_overhead = ((p_post - p_pre) / p_pre * 100) if p_pre and p_post else None

    rows.append({
        "DATA_W": data_w,
        "DEPTH": depth,
        "WMAX": wmax,
        "Cell_Count_Pre": pre_cc,
        "Area_Pre": pre_ta,
        "Cell_Count_Post": post_cc,
        "Area_Post": post_ta,
        "Area_Overhead_%": area_overhead,
        "Power_Pre_mW": p_pre,
        "Power_Post_mW": p_post,
        "Power_Overhead_%": power_overhead,
        "Scan_Chains": chains,
        "Scan_Registers": scan_regs,
    })

rows.sort(key=lambda r: (r["DATA_W"], r["DEPTH"], r["WMAX"]))

out = Path("results_summary.csv")
with out.open("w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=rows[0].keys())
    writer.writeheader()
    writer.writerows(rows)

headers = [
    "DATA_W", "DEPTH", "WMAX",
    "Area_Pre", "Area_Post", "Area_OH%",
    "Pwr_Pre", "Pwr_Post", "Pwr_OH%",
    "Chains", "Scan_Regs"
]

print()
print(" | ".join(f"{h:>10}" for h in headers))
print("-" * 132)

for r in rows:
    def fmt(v, n=3):
        return "-" if v is None else f"{v:.{n}f}"

    print(
        f"{r['DATA_W']:>10} | "
        f"{r['DEPTH']:>10} | "
        f"{r['WMAX']:>10} | "
        f"{fmt(r['Area_Pre']):>10} | "
        f"{fmt(r['Area_Post']):>10} | "
        f"{fmt(r['Area_Overhead_%'], 2):>10} | "
        f"{fmt(r['Power_Pre_mW'], 5):>10} | "
        f"{fmt(r['Power_Post_mW'], 5):>10} | "
        f"{fmt(r['Power_Overhead_%'], 2):>10} | "
        f"{str(r['Scan_Chains']):>10} | "
        f"{str(r['Scan_Registers']):>10}"
    )

print()
print(f"CSV gerado: {out}")
