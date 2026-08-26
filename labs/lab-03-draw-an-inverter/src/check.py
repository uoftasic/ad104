#!/usr/bin/env python3
"""Lab 03 verdict: is the thing you drew a CMOS inverter?

Reads what Magic and netgen produced and reports, in words, the things a first
hand-drawn cell actually gets wrong. Every message names the layer or the rule,
because "it failed" is not a diagnosis.
"""
from __future__ import annotations

import argparse
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
RESULTS = ROOT / "results"

WANT = {
    "nfet": ("sky130_fd_pr__nfet_01v8", 0.65, 0.15),
    "pfet": ("sky130_fd_pr__pfet_01v8_hvt", 1.0, 0.15),
}
PORTS = ["A", "Y", "VPWR", "VGND"]


def read_report(cell: str):
    path = RESULTS / ("report.txt" if cell == "my_inv" else "report_ref.txt")
    if not path.exists():
        sys.exit(
            "results/report.txt is missing, so Magic never got as far as a DRC count.\n"
            "Read results/magic.log. The usual cause is that mag/my_inv.mag does not\n"
            "exist yet - run `make scaffold` to lay down the frame."
        )
    out = {"why": [], "drc_fast": None, "drc_full": None}
    for line in path.read_text().splitlines():
        key, _, rest = line.partition(" ")
        if key == "DRC_FAST":
            out["drc_fast"] = int(rest)
        elif key == "DRC_FULL":
            out["drc_full"] = int(rest)
        elif key == "DRC_WHY":
            out["why"].append(rest)
    return out


def read_netlist(cell: str):
    path = RESULTS / f"{cell}.lvs.spice"
    if not path.exists():
        sys.exit(f"results/{cell}.lvs.spice is missing - extraction did not run.")
    text = path.read_text()
    ports: list[str] = []
    match = re.search(rf"^\.subckt\s+{re.escape(cell)}\s+(.*)$", text, re.M)
    if match:
        ports = match.group(1).split()
    devices = []
    for line in text.splitlines():
        if not line.startswith("X"):
            continue
        fields = line.split()
        model = next((f for f in fields if f.startswith("sky130_fd_pr__")), None)
        if model is None:
            continue
        params = {}
        for f in fields:
            k, _, v = f.partition("=")
            if k in {"w", "l", "ad", "as", "pd", "ps"}:
                params[k] = float(v)
        devices.append({"name": fields[0], "model": model, "nodes": fields[1:5], **params})
    return ports, devices


def lvs_verdict(cell: str):
    path = RESULTS / ("lvs.report" if cell == "my_inv" else "lvs_ref.report")
    if not path.exists():
        return "netgen wrote no report", ""
    text = path.read_text()
    match = re.search(r"Final result:\s*(.+)", text)
    verdict = match.group(1).strip() if match else "unknown"
    detail = ""
    if "failed pin matching" in verdict:
        names = re.findall(r"^(\S+)\s+\|(\S+)\s+\*\*Mismatch\*\*", text, re.M)
        if names:
            detail = ", ".join(f"{a} <-> {b}" for a, b in names)
    return verdict, detail


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--cell", default="my_inv")
    args = ap.parse_args()

    rep = read_report(args.cell)
    ports, devices = read_netlist(args.cell)
    verdict, detail = lvs_verdict(args.cell)

    problems: list[str] = []

    print()
    print(f"  WHAT MAGIC FOUND IN {args.cell}.mag")
    print()

    # ---- devices ---------------------------------------------------------
    nfets = [d for d in devices if "nfet" in d["model"]]
    pfets = [d for d in devices if "pfet" in d["model"]]
    print(f"      transistors            {len(devices)}   ({len(nfets)} n, {len(pfets)} p)")
    for d in devices:
        print(f"        {d['name']:<4} {d['model']:<32} W={d['w']:g}  L={d['l']:g}")

    if not devices:
        problems.append(
            "No transistors at all. A transistor is the place where a poly stripe\n"
            "      crosses a diffusion. If Magic sees no crossing, either the poly does\n"
            "      not overlap the diffusion, or one of them is not the layer you think\n"
            "      it is - check the layer name in the title bar as you paint."
        )
    if len(nfets) == 0 and devices:
        problems.append("No NMOS. Poly has to cross the ndiff, not stop at its edge.")
    if len(pfets) == 0 and devices:
        problems.append("No PMOS. Poly has to cross the pdiff, and the pdiff has to sit inside the nwell.")
    if len(devices) > 2:
        problems.append(
            f"{len(devices)} transistors, and an inverter has two. A poly stripe that\n"
            "      crosses one diffusion twice makes two devices in series - look for a\n"
            "      second crossing you did not mean to draw."
        )

    for kind, group in (("nfet", nfets), ("pfet", pfets)):
        model, w, l = WANT[kind]
        for d in group:
            if abs(d["l"] - l) > 1e-9:
                problems.append(
                    f"{d['name']} has L = {d['l']:g} um, not {l:g}. L is the width of the poly stripe "
                    f"where it crosses the diffusion."
                )
            if abs(d["w"] - w) > 1e-9:
                problems.append(
                    f"{d['name']} has W = {d['w']:g} um, not {w:g}. W is the height of the diffusion "
                    f"under the gate."
                )
            if d["model"] != model:
                if kind == "pfet":
                    problems.append(
                        f"{d['name']} came out as {d['model']}, not {model}.\n"
                        "      The foundry's PMOS is the high-Vt flavour. DRC will never mention\n"
                        "      this, and LVS will fail with a device-class mismatch. Paint the\n"
                        "      `pfethvt` layer over the gate region to fix it."
                    )
                else:
                    problems.append(f"{d['name']} came out as {d['model']}, not {model}.")

    # ---- ports -----------------------------------------------------------
    print()
    print(f"      ports                  {' '.join(ports) if ports else '(none)'}")
    missing = [p for p in PORTS if p not in ports]
    if missing:
        problems.append(
            f"No port called {', '.join(missing)}. Put the box over the shape you want to "
            "name,\n      then type `label <name>` in the console and re-run - a cell with no\n"
            "      ports cannot be compared against a schematic."
        )

    # ---- DRC -------------------------------------------------------------
    print()
    print(f"      DRC, default rule set  {rep['drc_fast']}")
    print(f"      DRC, full rule set     {rep['drc_full']}")
    if rep["why"]:
        print()
        print("      rules broken:")
        seen = []
        for w in rep["why"]:
            if w not in seen:
                seen.append(w)
                print(f"        {w}")
    if rep["drc_fast"]:
        problems.append(
            f"{rep['drc_fast']} DRC violations under the default rule set. Every one names\n"
            "      the rule it broke - fix them by rule, not by nudging shapes until the\n"
            "      white dots go away."
        )
    elif rep["drc_full"]:
        problems.append(
            f"Zero violations under the default rule set but {rep['drc_full']} under the full\n"
            "      one. The full set adds the rules that need context - well taps and\n"
            "      latch-up spacing. Your cell has taps in the frame, so if this fires you\n"
            "      have deleted or disconnected one of them."
        )

    # ---- LVS -------------------------------------------------------------
    print()
    print(f"      LVS                    {verdict}")
    if detail:
        print(f"        mismatched pins:     {detail}")
    print()

    if "Circuits match uniquely" not in verdict:
        if len(devices) != 2:
            problems.append(
                "LVS never got to a meaningful answer, because the two sides do not\n"
                "      contain the same number of devices. Fix the transistors first; the\n"
                "      netlist comparison is only interesting once both sides have two."
            )
        elif "pin matching" in verdict and detail:
            problems.append(
                "Netgen matched the circuit and disagreed about which pin is which\n"
                f"      ({detail}). The topology is right; two labels are on the wrong shapes."
            )
        elif "pin matching" in verdict:
            problems.append(
                "Netgen matched the circuit and could not match the pin lists. Usually a\n"
                "      missing label: a shape with no name has no pin to match."
            )
        else:
            problems.append(
                "LVS did not match. Read results/lvs.report from the bottom up - the\n"
                "      last table before the verdict names the device or net that has no\n"
                "      partner."
            )

    if not problems:
        print("PASS  Two transistors, the right flavours, the right W and L, four ports,")
        print("      zero DRC violations under both rule sets, and netgen agrees your")
        print("      geometry is the schematic.")
        print()
        print("      You drew a manufacturable CMOS inverter. Lab 05 will tell you what")
        print("      it costs against the foundry's.")
        return 0

    print("FAIL  " + problems[0])
    for extra in problems[1:]:
        print()
        print("      " + extra)
    print()
    print("      Fix one thing, run `make` again. That loop is the job.")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
