#!/usr/bin/env python3
"""Lab 04 verdict for `make gen`: is the generated cell the Lab 03 inverter?

Same shape as Lab 03's verdict: the transistors with their W, L and model, the
ports, DRC under both rule sets, and netgen's answer. The difference is the
hierarchy. Each device from Magic's generator is a cell of its own, so the
extracted netlist has a wrapper subcircuit per device (`.subckt
sky130_fd_pr__nfet_01v8_HFW449 B D S G`) holding one primitive transistor, and
an instance line per wrapper in my_inv_gen. Only lines whose model is one of
the foundry's primitives count as transistors; the wrapper instances do not.
"""
from __future__ import annotations

import argparse
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
RESULTS = ROOT / "results"

NFET = "sky130_fd_pr__nfet_01v8"
PFET = "sky130_fd_pr__pfet_01v8"
PFET_HVT = "sky130_fd_pr__pfet_01v8_hvt"
PRIMITIVES = {NFET, PFET, PFET_HVT}
WANT = {"nfet": (NFET, 0.65, 0.15), "pfet": (PFET_HVT, 1.0, 0.15)}
PORTS = ["A", "Y", "VPWR", "VGND"]


def read_report(cell: str):
    path = RESULTS / "gen_report.txt"
    if not path.exists():
        sys.exit("results/gen_report.txt is missing - Magic did not finish. Read results/magic_gen.log")
    out = {"why": [], "fast": None, "full": None}
    for line in path.read_text().splitlines():
        parts = line.split(" ", 2)
        if len(parts) < 3 or parts[0] != cell:
            continue
        _, kind, rest = parts
        if kind == "FAST":
            out["fast"] = int(rest)
        elif kind == "FULL":
            out["full"] = int(rest)
        elif kind == "WHY" and rest not in out["why"]:
            out["why"].append(rest)
    return out


def read_netlist(cell: str):
    path = RESULTS / f"{cell}.lvs.spice"
    if not path.exists():
        sys.exit(f"results/{cell}.lvs.spice is missing - extraction did not run. Read results/magic_gen.log")
    text = path.read_text()
    match = re.search(rf"^\.subckt\s+{re.escape(cell)}\b(.*)$", text, re.M)
    ports = match.group(1).split() if match else []
    devices = []
    for line in text.splitlines():
        if not line.startswith("X"):
            continue
        fields = line.split()
        model = next((f for f in fields if f in PRIMITIVES), None)
        if model is None:
            continue
        params = {}
        for f in fields:
            k, _, v = f.partition("=")
            if k in {"w", "l", "ad", "as", "pd", "ps"}:
                params[k] = float(v)
        devices.append({"model": model, **params})
    return ports, devices


def lvs_verdict(cell: str):
    path = RESULTS / f"{cell}.lvs.report"
    if not path.exists():
        return "netgen wrote no report"
    match = re.search(r"Final result:\s*(.+)", path.read_text())
    return match.group(1).strip() if match else "unknown"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--cell", default="my_inv_gen")
    args = ap.parse_args()

    rep = read_report(args.cell)
    ports, devices = read_netlist(args.cell)
    verdict = lvs_verdict(args.cell)
    problems: list[str] = []

    print()
    print(f"  THE GENERATED INVERTER, {args.cell}")
    print()
    nfets = [d for d in devices if "nfet" in d["model"]]
    pfets = [d for d in devices if "pfet" in d["model"]]
    print(f"      transistors            {len(devices)}   ({len(nfets)} n, {len(pfets)} p)")
    for d in devices:
        print(f"        {d['model']:<32} W={d.get('w', 0):g}  L={d.get('l', 0):g}")

    if not devices:
        problems.append(
            "No transistors. Place them with Devices 1 → nmos (MOSFET) and\n"
            "      Devices 1 → pmos (MOSFET) (Part 7), then save with autowrite so\n"
            "      the device cells are written into mag/ too."
        )
    if devices and not nfets:
        problems.append("No NMOS. Place one with Devices 1 → nmos (MOSFET).")
    if devices and not pfets:
        problems.append("No PMOS. Place one with Devices 1 → pmos (MOSFET).")
    if len(devices) > 2:
        problems.append(
            f"{len(devices)} transistors, and an inverter has two. Look for a device you\n"
            "      placed twice, or Fingers set above 1 in the device window."
        )
    for kind, group in (("nfet", nfets), ("pfet", pfets)):
        model, w, l = WANT[kind]
        for d in group:
            if abs(d.get("l", 0) - l) > 1e-9:
                problems.append(f"A {kind} has L = {d.get('l', 0):g} um, not {l:g}. Set Length (um) in the device window.")
            if abs(d.get("w", 0) - w) > 1e-9:
                problems.append(f"A {kind} has W = {d.get('w', 0):g} um, not {w:g}. Set Width (um) in the device window.")
            if d["model"] != model:
                problems.append(
                    f"The PMOS came out as {d['model']}, not {model}.\n"
                    "      Pick the hvt device: point at the pmos, press i, then q, set\n"
                    f"      Device type to {PFET_HVT} and click Okay."
                )

    print()
    print(f"      ports                  {' '.join(ports) if ports else '(none)'}")
    missing = [p for p in PORTS if p not in ports]
    if missing:
        problems.append(
            f"No port called {', '.join(missing)}. Put the box on metal1 that you painted\n"
            "      in my_inv_gen itself, open Edit → Text ..., type the name, tick Port\n"
            "      enable and click Okay. A label over a device cell's own metal stays\n"
            "      in my_inv_gen with nothing of my_inv_gen's under it, and names no net."
        )

    print()
    print(f"      DRC, default rule set  {rep['fast']}")
    print(f"      DRC, full rule set     {rep['full']}")
    if rep["why"]:
        print()
        print("      rules broken:")
        for w in rep["why"]:
            print(f"        {w}")
    if any("met1.6" in w for w in rep["why"]):
        problems.append(
            "met1.6: a piece of metal1 below the minimum area. A gate contact the\n"
            "      wiring does not use is a lone 0.29 x 0.23 um pad. Untick it: point at\n"
            "      the device, press i, then q, untick Add bottom gate contact (nmos) or\n"
            "      Add top gate contact (pmos), click Okay, and re-check the wiring that\n"
            "      touched that device, because it moves."
        )
    elif rep["fast"] or rep["full"]:
        problems.append(
            "DRC violations. Every one names the rule it broke: run Drc → DRC update\n"
            "      and Drc → DRC report in Magic, or read the rules listed above."
        )

    print()
    print(f"      LVS                    {verdict}")
    print()
    if "Circuits match uniquely" not in verdict and not missing and len(devices) == 2:
        if "pin matching" in verdict:
            problems.append(
                "Netgen matched the circuit and could not match the pin names. Two\n"
                "      labels are on the wrong shapes, or one is missing."
            )
        else:
            problems.append(
                f"LVS says {verdict}. Read results/{args.cell}.lvs.report from the bottom\n"
                "      up: the last table names the device or net with no partner. The\n"
                "      usual cause is a wire that stops short of a device's pad or strip,\n"
                "      or a guard ring with no tie to its rail."
            )

    if not problems:
        print("PASS  Two generated transistors, the right flavours, W and L, four ports,")
        print("      zero DRC violations under both rule sets, and netgen agrees it is")
        print("      the inverter.")
        return 0

    print("FAIL  " + problems[0])
    for extra in problems[1:]:
        print()
        print("      " + extra)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
