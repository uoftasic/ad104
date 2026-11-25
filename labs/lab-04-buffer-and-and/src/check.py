#!/usr/bin/env python3
"""Lab 04 verdict: two blocks made of cells, and does the AND actually AND."""
from __future__ import annotations

import argparse
import pathlib
import re
import sys

RESULTS = pathlib.Path(__file__).resolve().parents[1] / "results"
TRUTH = {"x00": 0.0, "x01": 0.0, "x10": 0.0, "x11": 1.8}
PORTS = {
    "my_buf": ["A", "X", "VGND", "VPWR"],
    "my_and2": ["A", "B", "X", "VGND", "VPWR"],
    "buf_ref": ["A", "X", "VGND", "VPWR"],
    "and_ref": ["A", "B", "X", "VGND", "VPWR"],
}


def read_report(cells):
    path = RESULTS / "report.txt"
    if not path.exists():
        sys.exit("results/report.txt is missing - Magic did not finish. Read results/magic.log")
    fast, full, why = {}, {}, {c: [] for c in cells}
    for line in path.read_text().splitlines():
        parts = line.split(" ", 2)
        if len(parts) < 3 or parts[0] not in fast.keys() | set(cells):
            if len(parts) < 3:
                continue
        cell, kind, rest = parts
        if cell not in cells:
            continue
        if kind == "FAST":
            fast[cell] = int(rest)
        elif kind == "FULL":
            full[cell] = int(rest)
        elif kind == "WHY" and rest not in why[cell]:
            why[cell].append(rest)
    return fast, full, why


def lvs(cell):
    path = RESULTS / f"{cell}.lvs.report"
    if not path.exists():
        return "no report"
    text = path.read_text()
    if "Circuits match uniquely" in text:
        return "match"
    match = re.search(r"Final result:\s*(.+)", text)
    return match.group(1).strip().rstrip(".") if match else "unknown"


def subcells(cell):
    path = RESULTS / f"{cell}.lvs.spice"
    if not path.exists():
        return []
    body = re.search(rf"^\.subckt\s+{re.escape(cell)}\b.*?^\.ends", path.read_text(), re.M | re.S)
    if not body:
        return []
    return [line.split()[-1] for line in body.group(0).splitlines() if line.startswith("X")]


def ports(cell):
    path = RESULTS / f"{cell}.lvs.spice"
    if not path.exists():
        return []
    m = re.search(rf"^\.subckt\s+{re.escape(cell)}([^\n]*)$", path.read_text(), re.M)
    return m.group(1).split() if m else []


def measurements():
    path = RESULTS / "and2.log"
    if not path.exists():
        return {}
    out = {}
    for line in path.read_text().splitlines():
        m = re.match(r"^(x\d\d)\s*=\s*([-\d.eE+]+)", line.strip())
        if m:
            out[m.group(1)] = float(m.group(2))
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--layout-only", action="store_true")
    ap.add_argument("--suffix", default="")
    args = ap.parse_args()

    names = ("my_buf", "my_and2") if not args.suffix else ("buf_ref", "and_ref")
    fast, full, why = read_report(names)

    problems = []
    print()
    print("  TWO BLOCKS, BUILT OUT OF CELLS")
    print()
    print(f"  {'block':<10}{'DRC default':>12}{'DRC full':>10}   {'LVS':<24}  contains")
    print(f"  {'-'*10}{'-'*12}{'-'*10}   {'-'*24}  {'-'*28}")
    for c in names:
        v = lvs(c)
        kids = subcells(c)
        ok = fast.get(c, 1) == 0 and full.get(c, 1) == 0 and v == "match"
        mark = "ok " if ok else "   "
        print(f"  {mark}{c:<7}{fast.get(c,'?'):>12}{full.get(c,'?'):>10}   {v:<24}  {', '.join(kids) or '(nothing)'}")
        if not kids:
            problems.append(
                f"{c} contains no subcells at all. `make scaffold` puts the two cells\n"
                "      back; without them there is nothing to wire together."
            )
        missing = [p for p in PORTS.get(c, []) if p not in ports(c)]
        if missing:
            problems.append(
                f"{c} has no port called {', '.join(missing)}. Its ports are: "
                f"{' '.join(ports(c)) or '(none)'}.\n"
                "      A label goes into the cell you are editing, so one put over a\n"
                "      subcell's pin stays in this block - but this block has no shape of\n"
                "      its own under it, so the label sits on empty space, and a label on\n"
                "      space names no net. Paint your own small patch of li over the pin\n"
                "      (same net, electrically nothing) and Magic moves the label onto it\n"
                "      (\"Moving label ... from space to locali\")."
            )
        if fast.get(c, 1) or full.get(c, 1):
            problems.append(f"{c} has DRC violations: " + "; ".join(why[c]))
        if v != "match" and not missing:
            if "pin matching" in v:
                problems.append(
                    f"{c}: netgen matched the circuit and could not match the pin names.\n"
                    "      Two labels are on the wrong shapes, or one is missing. Part 6 of the\n"
                    "      lab shows this failure on purpose so you can recognise it."
                )
            elif kids:
                problems.append(
                    f"{c}: LVS says {v}. The usual cause here is the wire between the two\n"
                    "      cells: if it does not actually land on both li pins, the extracted\n"
                    "      netlist has an extra net and one input floating."
                )
    print()

    if problems and not args.layout_only:
        print("  THE AND GATE, SIMULATED")
        print()
        print("      Not simulated. A truth table taken from a block that does not yet")
        print("      match its schematic would be a fact about the wrong circuit.")
        print()
    elif not args.layout_only:
        meas = measurements()
        print("  THE AND GATE, SIMULATED")
        print()
        if not meas:
            problems.append(
                "ngspice produced no measurements. Read results/and2.log - the first\n"
                "      'Error on line' in it is the real message."
            )
        else:
            for key, want in TRUTH.items():
                got = meas.get(key)
                a, b = key[1], key[2]
                if got is None:
                    problems.append(f"no measurement for A={a} B={b}")
                    continue
                if abs(got) < 5e-7:
                    got = 0.0
                good = abs(got - want) < 0.09
                if not good:
                    problems.append(f"A={a}, B={b} should give {want:.1f} V and gives {got:.4f} V")
                print(f"      {'ok ' if good else 'BAD'} A={a}  B={b}   X = {got:.6f} V   (expected {want:.1f})")
        print()

    if not problems:
        if args.layout_only:
            print("PASS  Both blocks are clean under both rule sets and netgen agrees they")
            print("      are what the schematic says.")
        else:
            print("PASS  A buffer and an AND gate, both clean under both rule sets, both")
            print("      matching their schematics, and the AND gate really does AND.")
            print()
            print("      Neither one contains a single new transistor. You drew two cells")
            print("      and then spent this lab arranging them - which is what the rest of")
            print("      a chip is.")
        return 0

    print("FAIL  " + problems[0])
    for extra in problems[1:]:
        print()
        print("      " + extra)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
