#!/usr/bin/env python3
"""Capstone verdict: four cells, three wires, and the clock ceiling they set."""
from __future__ import annotations

import argparse
import pathlib
import re
import sys

RESULTS = pathlib.Path(__file__).resolve().parents[1] / "results"

EXPECTED_CELLS = {
    "sky130_fd_sc_hd__dfxtp_1": 1,
    "sky130_fd_sc_hd__and2_0": 2,
    "sky130_fd_sc_hd__buf_1": 1,
}


def read_report():
    path = RESULTS / "report.txt"
    if not path.exists():
        sys.exit("results/report.txt is missing - Magic did not finish. Read results/magic.log")
    out = {"why": []}
    for line in path.read_text().splitlines():
        key, _, rest = line.partition(" ")
        if key == "DRC_FAST":
            out["fast"] = int(rest)
        elif key == "DRC_FULL":
            out["full"] = int(rest)
        elif key == "DRC_WHY" and rest not in out["why"]:
            out["why"].append(rest)
        elif key == "BBOX_UM":
            w, h = rest.split()
            out["w"], out["h"] = float(w), float(h)
        elif key == "CELL":
            out["cell"] = rest
        elif key == "CHILD":
            out.setdefault("children", []).append(rest)
    return out


def instances(cell):
    path = RESULTS / f"{cell}.lvs.spice"
    if not path.exists():
        return {}, []
    text = path.read_text()
    body = re.search(
        rf"^\.subckt\s+{re.escape(cell)}([^\n]*)\n(.*?)^\.ends", text, re.M | re.S
    )
    if not body:
        return {}, []
    counts: dict[str, int] = {}
    for line in body.group(2).splitlines():
        if line.startswith("X"):
            counts[line.split()[-1]] = counts.get(line.split()[-1], 0) + 1
    return counts, body.group(1).split()


def lvs():
    path = RESULTS / "lvs.report"
    if not path.exists():
        return "no report"
    text = path.read_text()
    if "Circuits match uniquely" in text:
        return "match"
    m = re.search(r"Final result:\s*(.+)", text)
    return m.group(1).strip().rstrip(".") if m else "unknown"


def timing():
    path = RESULTS / "timing.log"
    if not path.exists():
        return None
    m = re.search(r"^t_clk_y\s*=\s*([-\d.eE+]+)", path.read_text(), re.M)
    return float(m.group(1)) if m else None


def setup_ns():
    path = RESULTS / "setup.txt"
    if not path.exists():
        return None
    try:
        return float(path.read_text().strip())
    except ValueError:
        return None


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--layout-only", action="store_true")
    ap.add_argument("--cell", default="datapath")
    args = ap.parse_args()

    rep = read_report()
    cell = rep.get("cell", args.cell)
    counts, ports = instances(cell)
    verdict = lvs()
    problems = []

    print()
    print("  YOUR BLOCK")
    print()
    print(f"      outline                {rep.get('w', 0):.2f} x {rep.get('h', 0):.2f} um"
          f"   =  {rep.get('w', 0) * rep.get('h', 0):.2f} um2")
    print(f"      cells placed           " + (", ".join(f"{n} x {c.replace('sky130_fd_sc_hd__','')}"
                                                       for c, n in sorted(counts.items())) or "(none)"))
    kids = [c.replace("sky130_fd_sc_hd__", "") for c in rep.get("children", [])]
    print(f"      cells in the row       {', '.join(sorted(kids)) if kids else '(none)'}")
    print(f"      ports                  {' '.join(ports) if ports else '(none)'}")
    print(f"      DRC, default rule set  {rep.get('fast', '?')}")
    print(f"      DRC, full rule set     {rep.get('full', '?')}")
    print(f"      LVS                    {verdict}")
    print()
    if rep["why"]:
        print("      rules broken:")
        for w in rep["why"]:
            print(f"        {w}")
        print()

    for want, n in EXPECTED_CELLS.items():
        got = counts.get(want, 0)
        if got != n:
            problems.append(
                f"{n} x {want} expected, {got} found. `make scaffold` puts the row back."
            )
    if rep.get("fast", 1):
        problems.append(
            f"{rep['fast']} DRC violations under the default rule set. In this lab they are\n"
            "      almost always metal1: a wire closer than 0.14 um to the rail or to the\n"
            "      next net, or a pad that does not surround its mcon by enough."
        )
    elif rep.get("full", 1):
        tap = any("nwell.4" in w or "LU." in w for w in rep["why"])
        if tap:
            problems.append(
                "Clean under the default rule set, and NOT clean under the full one.\n"
                "      Every violation is about well taps. Nothing in your row ties the\n"
                "      nwell to VPWR or the substrate to VGND, because sky130_fd_sc_hd\n"
                "      cells are drawn tapless on purpose - the taps are a separate cell.\n"
                "      Place a sky130_fd_sc_hd__tapvpwrvgnd_1 at each end of the row.\n"
                "      Look at the extracted netlist too: the body terminals come out on\n"
                "      a node called VSUBS instead of VGND, which is the same fault seen\n"
                "      by a different tool."
            )
        else:
            problems.append(
                f"{rep['full']} violations under the full rule set: " + "; ".join(rep["why"])
            )
    if verdict != "match":
        if "pin matching" in verdict:
            problems.append(
                "netgen matched the circuit and could not match the pins. Every one of\n"
                "      CLK D A B Y VGND VPWR has to be a label on a shape painted in the top\n"
                "      cell. A label over a standard cell's rail or pin stays in your block,\n"
                "      but with no shape of your block's under it Magic moves it onto empty\n"
                "      space, and a label on space names no net."
            )
        elif counts and not any("tapvpwrvgnd" in c for c in rep.get("children", [])):
            problems.append(
                f"LVS says {verdict}, and the row has no tap cells yet, which is enough\n"
                "      on its own to cause it. Without taps the cells' bodies come out on\n"
                "      invented nodes such as VSUBS and dff0/VPB instead of VGND and VPWR\n"
                f"      (`grep Xbuf0 results/{cell}.lvs.spice` shows them), and the\n"
                "      schematic has them on the supplies. Place the taps and run `make\n"
                "      layout` again. If LVS still fails after that, read results/lvs.report\n"
                "      from the bottom: an unrouted net shows up as two nets on your side\n"
                "      and one on the schematic's."
            )
        elif counts:
            problems.append(
                f"LVS says {verdict}. Read results/lvs.report from the bottom: the last\n"
                "      table before the verdict names the net or device with no partner.\n"
                "      An unrouted net shows up as two nets on your side and one on the\n"
                "      schematic's."
            )

    if problems and not args.layout_only:
        print("  HOW FAST CAN YOU CLOCK IT")
        print()
        print("      Not measured. Timing on a layout that is not yet clean and")
        print("      matching would be a number about the wrong circuit.")
        print()

    if args.layout_only or problems:
        if problems:
            print("FAIL  " + problems[0])
            for extra in problems[1:]:
                print()
                print("      " + extra)
            return 1
        print("PASS  Four cells, three hand-routed nets, clean under both rule sets, and")
        print("      netgen agrees it is the netlist you were given.")
        return 0

    # ---------------- timing --------------------------------------------
    t = timing()
    ts = setup_ns()
    print("  HOW FAST CAN YOU CLOCK IT")
    print()
    if t is None:
        problems.append(
            "ngspice measured no clock-to-Y delay. Read results/timing.log; the first\n"
            "      'Error on line' is the real message."
        )
    else:
        tps = t * 1e12
        print(f"      CLK rise -> Y rise      {tps:8.2f} ps    (measured on your extracted layout)")
        if ts is None:
            print("      setup time              (Liberty file not found)")
        else:
            print(f"      D setup at the flop     {ts * 1000:8.2f} ps    "
                  f"(sky130_fd_sc_hd__tt_025C_1v80.lib)")
            period = tps + ts * 1000
            print(f"      shortest legal period   {period:8.2f} ps")
            print(f"      f_max                   {1e6 / period:8.2f} MHz")
            print()
            print("      That is one flip-flop, two AND gates and a buffer - four levels of")
            print("      logic, 15 um of chip, and no long wires at all. A real design has")
            print("      twenty to forty levels on its worst path and millimetres of wire on")
            print("      top of that, which is the whole answer to why a chip you can buy")
            print("      runs at a few hundred megahertz and not at a few gigahertz.")
            print()
            print("      Note which cells you were given: and2_0 is the WEAKEST AND in the")
            print("      library. Swapping the two for and2_2 would cost area and buy back")
            print("      a real slice of that delay. That trade, made a few million times,")
            print("      is what a synthesis tool spends its afternoon on.")
    print()

    if problems:
        print("FAIL  " + problems[0])
        for extra in problems[1:]:
            print()
            print("      " + extra)
        return 1

    print("PASS  You placed four standard cells, routed three nets by hand, got a row")
    print("      that is clean under the full SKY130 rule set, proved with netgen that")
    print("      it is the circuit you were given, and then measured the clock ceiling")
    print("      of your own layout.")
    print()
    print("      `make gds` writes the file a foundry would take.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
