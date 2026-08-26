#!/usr/bin/env python3
"""Lab 01 verdict: did Magic and netgen agree with the foundry about its own cell?

Reads results/report.txt (written by tcl/inspect.tcl) and results/lvs.report
(written by netgen) and prints every number this lab teaches, next to the value
a clean run produces.
"""
from __future__ import annotations

import pathlib
import re
import sys

RESULTS = pathlib.Path(__file__).resolve().parents[1] / "results"
CELL = "sky130_fd_sc_hd__inv_1"

REFERENCE = {
    "drc_fast": 0,
    "drc_full": 3,
    "width_um": 1.38,
    "height_um": 2.72,
    "devices": 2,
    "nfet_w": 0.65,
    "pfet_w": 1.0,
    "length": 0.15,
}


def read_report() -> dict:
    path = RESULTS / "report.txt"
    if not path.exists():
        sys.exit("results/report.txt is missing - Magic did not finish. Read results/magic.log")
    out: dict = {"why": []}
    for line in path.read_text().splitlines():
        key, _, rest = line.partition(" ")
        if key == "DRC_FAST":
            out["drc_fast"] = int(rest)
        elif key == "DRC_FULL":
            out["drc_full"] = int(rest)
        elif key == "DRC_WHY":
            out["why"].append(rest)
        elif key == "FIXED_BBOX":
            x1, y1, x2, y2 = (int(v) for v in rest.split())
            out["width_um"] = round((x2 - x1) * 0.005, 4)
            out["height_um"] = round((y2 - y1) * 0.005, 4)
    return out


def read_devices() -> list[dict]:
    path = RESULTS / f"{CELL}.lvs.spice"
    if not path.exists():
        sys.exit(f"results/{CELL}.lvs.spice is missing - extraction did not run.")
    devices = []
    for line in path.read_text().splitlines():
        if not line.startswith("X"):
            continue
        fields = line.split()
        model = next((f for f in fields if f.startswith("sky130_fd_pr__")), None)
        if model is None:
            continue
        params = dict(
            (k, float(v))
            for k, _, v in (f.partition("=") for f in fields)
            if k in {"w", "l", "ad", "as", "pd", "ps"}
        )
        devices.append({"name": fields[0], "model": model, **params})
    return devices


def lvs_verdict() -> str:
    path = RESULTS / "lvs.report"
    if not path.exists():
        return "netgen wrote no report"
    text = path.read_text()
    if "Circuits match uniquely" in text:
        return "Circuits match uniquely"
    match = re.search(r"Final result:\s*(.+)", text)
    return match.group(1).strip() if match else "unknown"


def main() -> int:
    rep = read_report()
    devices = read_devices()
    lvs = lvs_verdict()

    print()
    print("  THE FOUNDRY'S INVERTER, MEASURED BY YOUR TOOLS")
    print()
    rows = [
        ("cell width", f"{rep['width_um']:.2f} um", REFERENCE["width_um"], rep["width_um"]),
        ("cell height", f"{rep['height_um']:.2f} um", REFERENCE["height_um"], rep["height_um"]),
        ("DRC violations, default style", f"{rep['drc_fast']}", REFERENCE["drc_fast"], rep["drc_fast"]),
        ("DRC violations, full style", f"{rep['drc_full']}", REFERENCE["drc_full"], rep["drc_full"]),
        ("devices extracted", f"{len(devices)}", REFERENCE["devices"], len(devices)),
    ]
    ok = True
    for label, shown, want, got in rows:
        good = abs(float(got) - float(want)) < 1e-6
        ok &= good
        print(f"  {'ok ' if good else 'BAD'} {label:<32} {shown:>14}   (reference {want})")

    print()
    area = rep["width_um"] * rep["height_um"]
    print(f"      cell area  {rep['width_um']:.2f} x {rep['height_um']:.2f} = {area:.4f} um^2")
    print()
    print("  THE TWO TRANSISTORS IT FOUND")
    for d in devices:
        print(
            f"      {d['name']}  {d['model']:<32} "
            f"W={d['w']:g}  L={d['l']:g}   drain area {d.get('ad', 0):g} um^2"
        )

    print()
    print(f"  LVS: {lvs}")
    print()

    if rep["why"]:
        print("  THE THREE THINGS THE FULL RULE SET COMPLAINS ABOUT")
        for w in rep["why"]:
            if w.startswith("{"):
                continue
            print(f"      {w}")
        print()
        print("      All three are the same omission: this cell contains no well tap.")
        print("      That is deliberate. sky130_fd_sc_hd cells are drawn tapless and the")
        print("      taps arrive as separate tapvpwrvgnd cells dropped into the row. A")
        print("      cell cannot satisfy nwell.4 on its own, because the rule is about")
        print("      the row it ends up in. You will fix exactly this in the capstone.")
        print()

    if ok and lvs == "Circuits match uniquely":
        print("PASS  Magic read the foundry's own layout, found zero violations under the")
        print("      default rule set and the three expected context rules under the full")
        print("      one, pulled two transistors out of the geometry, and netgen agreed")
        print("      they are the circuit the foundry says the cell is.")
        print("      Your toolchain is correct. Everything that goes wrong from here is")
        print("      your drawing, which is a much better problem to have.")
        return 0

    print("FAIL  Something above does not match. If the default-style DRC count is not")
    print("      zero on a cell you did not draw, the problem is almost certainly")
    print("      PDK_ROOT or the .magicrc, not the cell - see the error table in the")
    print("      lab writeup.")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
