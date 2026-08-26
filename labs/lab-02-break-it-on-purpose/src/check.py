#!/usr/bin/env python3
"""Lab 02 verdict: five cells, five rules, and whether you fixed them.

A cell counts as fixed when it is clean under BOTH rule sets and netgen still
recognises it as the inverter it started as. Deleting the offending shape
usually satisfies the first and fails the second, which is the point.
"""
from __future__ import annotations

import pathlib
import re
import sys

RESULTS = pathlib.Path(__file__).resolve().parents[1] / "results"
CELLS = ["drc_01", "drc_02", "drc_03", "drc_04", "drc_05"]

# What each cell looks like before you touch it.
AS_SHIPPED = {
    "drc_01": (3, 3, "N-well overlap of P-Diffusion < 0.18um (diff/tap.8)"),
    "drc_02": (2, 2, "Local interconnect overlap of poly contact < 0.08um in one direction (li.5)"),
    "drc_03": (14, 14, "poly overlap of poly contact < 0.05um (licon.8)"),
    "drc_04": (2, 2, "Local interconnect spacing < 0.17um (li.3)"),
    "drc_05": (0, 1, "All nwells must contain metal-connected N+ taps (nwell.4)"),
}


def read_report():
    path = RESULTS / "report.txt"
    if not path.exists():
        sys.exit("results/report.txt is missing - Magic did not finish. Read results/magic.log")
    fast, full, why = {}, {}, {c: [] for c in CELLS}
    for line in path.read_text().splitlines():
        parts = line.split(" ", 2)
        if len(parts) < 3:
            continue
        cell, kind, rest = parts
        if kind == "FAST":
            fast[cell] = int(rest)
        elif kind == "FULL":
            full[cell] = int(rest)
        elif kind == "WHY" and rest not in why[cell]:
            why[cell].append(rest)
    return fast, full, why


def lvs(cell: str) -> str:
    path = RESULTS / f"{cell}.lvs.report"
    if not path.exists():
        return "no report"
    text = path.read_text()
    if "Circuits match uniquely" in text:
        return "match"
    match = re.search(r"Final result:\s*(.+)", text)
    return (match.group(1).strip().rstrip(".") if match else "unknown")


def main() -> int:
    fast, full, why = read_report()
    print()
    print("  FIVE CELLS, FIVE MISTAKES")
    print()
    print(f"  {'cell':<9}{'DRC default':>12}{'DRC full':>10}   {'LVS':<24}")
    print(f"  {'-'*9}{'-'*12}{'-'*10}   {'-'*24}")
    fixed = []
    for c in CELLS:
        v = lvs(c)
        done = fast.get(c, 1) == 0 and full.get(c, 1) == 0 and v == "match"
        fixed.append(done)
        mark = "ok " if done else "   "
        print(f"  {mark}{c:<6}{fast.get(c, '?'):>12}{full.get(c, '?'):>10}   {v:<24}")
    print()

    for c in CELLS:
        if why[c]:
            print(f"  {c} still breaks:")
            for w in why[c]:
                print(f"      {w}")
    if any(why.values()):
        print()

    broke_circuit = [c for c in CELLS if lvs(c) != "match"]
    if broke_circuit and all(fast.get(c, 1) == 0 and full.get(c, 1) == 0 for c in broke_circuit):
        print("  Note: " + ", ".join(broke_circuit) + " is clean and no longer an inverter.")
        print("  Erasing the shape that broke the rule is not a fix. Move it, resize it,")
        print("  or add the thing it needed - the circuit has to survive.")
        print()

    if all(fixed):
        print("PASS  All five are clean under both rule sets and all five are still the")
        print("      inverter you started with. You have now read five real SKY130 rule")
        print("      names and know what each one is protecting.")
        print()
        print("      The one worth remembering is drc_05. It was clean under the default")
        print("      rule set from the very first run, and wrong the whole time.")
        return 0

    todo = [c for c, ok in zip(CELLS, fixed) if not ok]
    print(f"FAIL  Still to fix: {', '.join(todo)}")
    print()
    print("      `make why C=3` prints every violation in cell 3 with its rule name.")
    print("      `make edit C=3` opens it in Magic. Inside Magic, put the cursor box")
    print("      over a white error dot and type `drc why`.")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
