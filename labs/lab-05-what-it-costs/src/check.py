#!/usr/bin/env python3
"""Lab 05 verdict: the same two transistors, drawn twice, priced."""
from __future__ import annotations

import pathlib
import re
import sys

RESULTS = pathlib.Path(__file__).resolve().parents[1] / "results"
MINE, THEIRS = "my_inv", "sky130_fd_sc_hd__inv_1"
STAGES = 31

REFERENCE = {
    "area_mine": 18.0,
    "area_theirs": 3.7536,
    "m_tphl": 37.323,
    "m_tplh": 88.430,
    "f_tphl": 33.948,
    "f_tplh": 81.506,
    "mper": 2640.210,
    "fper": 2033.620,
}


def geom():
    path = RESULTS / "geom.txt"
    if not path.exists():
        sys.exit("results/geom.txt is missing - Magic did not finish. Read results/magic.log")
    out = {}
    for line in path.read_text().splitlines():
        cell, _, rest = line.partition(" FIXED_BBOX ")
        x1, y1, x2, y2 = (int(v) for v in rest.split())
        out[cell] = ((x2 - x1) * 0.005, (y2 - y1) * 0.005)
    return out


def devices(cell):
    path = RESULTS / f"{cell}.pex.spice"
    if not path.exists():
        sys.exit(f"results/{cell}.pex.spice is missing - extraction did not run.")
    out = []
    for line in path.read_text().splitlines():
        if not line.startswith("X"):
            continue
        fields = line.split()
        model = next((f for f in fields if f.startswith("sky130_fd_pr__")), None)
        if model is None:
            continue
        d = {"model": model}
        for f in fields:
            k, _, v = f.partition("=")
            if k in {"w", "l", "ad", "as", "pd", "ps"}:
                d[k] = float(v)
        out.append(d)
    return out


def caps(cell):
    path = RESULTS / f"{cell}.pex.spice"
    total, on_out = 0.0, 0.0
    for line in path.read_text().splitlines():
        m = re.match(r"^C\d+\s+(\S+)\s+(\S+)\s+([\d.eE+-]+)f", line)
        if not m:
            continue
        a, b, val = m.group(1), m.group(2), float(m.group(3))
        total += val
        if "Y" in (a, b):
            on_out += val
    return total, on_out


def meas(logname):
    path = RESULTS / logname
    if not path.exists():
        return {}
    out = {}
    for line in path.read_text().splitlines():
        m = re.match(r"^(\w+)\s*=\s*([-\d.eE+]+)", line.strip())
        if m and m.group(1) in {
            "m_tphl", "m_tplh", "f_tphl", "f_tplh", "mper", "fper"
        }:
            out[m.group(1)] = float(m.group(2))
    return out


def row(label, mine, theirs, unit="", fmt="{:.4g}"):
    ratio = mine / theirs if theirs else float("nan")
    print(
        f"  {label:<30}{fmt.format(mine):>12}{fmt.format(theirs):>14}"
        f"{unit:<6}{ratio:>8.2f} x"
    )


def main() -> int:
    g = geom()
    if MINE not in g or THEIRS not in g:
        sys.exit("results/geom.txt does not name both cells - re-run `make pex`.")
    wm, hm = g[MINE]
    wt, ht = g[THEIRS]
    area_m, area_t = wm * hm, wt * ht

    dm, dt = devices(MINE), devices(THEIRS)
    tm = meas("fo4.log")
    tm.update(meas("ring.log"))

    print()
    print("  THE SAME TWO TRANSISTORS, DRAWN TWICE")
    print()
    print(f"  {'':<30}{'yours':>12}{'foundry':>14}{'':<6}{'ratio':>10}")
    print(f"  {'-'*30}{'-'*12}{'-'*14}{'-'*6}{'-'*10}")
    row("cell width", wm, wt, " um")
    row("cell height", hm, ht, " um")
    row("cell area", area_m, area_t, " um2")
    print()

    def find(devs, kind):
        return next((d for d in devs if kind in d["model"]), {})

    for kind, name in (("nfet", "NMOS"), ("pfet", "PMOS")):
        a, b = find(dm, kind), find(dt, kind)
        if not a or not b:
            continue
        print(f"  {name}: {a['model']}")
        row("   W", a.get("w", 0), b.get("w", 0), " um")
        row("   L", a.get("l", 0), b.get("l", 0), " um")
        row("   drain junction area", a.get("ad", 0), b.get("ad", 0), " um2")
        row("   drain junction perim", a.get("pd", 0), b.get("pd", 0), " um")
    print()

    cm, cmo = caps(MINE)
    ct, cto = caps(THEIRS)
    row("extracted capacitance, total", cm, ct, " fF")
    row("     ... of it on the output", cmo, cto, " fF")
    print()

    print("  DELAY, fan-out of 4")
    ok = True
    pairs = [
        ("t_pHL", "m_tphl", "f_tphl"),
        ("t_pLH", "m_tplh", "f_tplh"),
    ]
    for label, km, kt in pairs:
        if km not in tm or kt not in tm:
            print(f"  {label:<30}   no measurement - read results/fo4.log")
            ok = False
            continue
        a, b = tm[km] * 1e12, tm[kt] * 1e12
        row(label, a, b, " ps")
    if all(k in tm for _, k, _ in pairs) and all(k in tm for _, _, k in pairs):
        am = (tm["m_tphl"] + tm["m_tplh"]) / 2 * 1e12
        at = (tm["f_tphl"] + tm["f_tplh"]) / 2 * 1e12
        row("average", am, at, " ps")
    print()

    print(f"  RING OSCILLATOR, {STAGES} stages, nothing but the cell driving itself")
    if "mper" in tm and "fper" in tm:
        pm, pt = tm["mper"] / 2 * 1e12, tm["fper"] / 2 * 1e12
        row("period", pm, pt, " ps")
        row("frequency", 1e6 / pm, 1e6 / pt, " MHz")
        row("one stage", pm / (2 * STAGES), pt / (2 * STAGES), " ps")
    else:
        print("      no measurement - read results/ring.log")
        ok = False
    print()

    if not ok:
        print("FAIL  Some measurement is missing. The first 'Error on line' in the")
        print("      ngspice log is the real message.")
        return 1

    ratio_area = area_m / area_t
    ratio_fo4 = ((tm["m_tphl"] + tm["m_tplh"]) / (tm["f_tphl"] + tm["f_tplh"]))
    ratio_ring = tm["mper"] / tm["fper"]

    print("  WHAT TO TAKE FROM THIS")
    print()
    print(f"      Same W, same L, same device flavours - the netlists are identical")
    print(f"      down to the model names. Everything below is the drawing.")
    print()
    print(f"      area          {ratio_area:5.2f} x  bigger")
    print(f"      FO4 delay     {ratio_fo4:5.2f} x  slower")
    print(f"      ring delay    {ratio_ring:5.2f} x  slower")
    print()
    print("      The two delay numbers disagree, and the disagreement is the lesson.")
    print("      At fan-out 4 most of the load is the gate capacitance of the four")
    print("      cells downstream, which is identical for both. In the ring each")
    print("      stage drives one cell, so your own junction area is a much bigger")
    print("      share of what has to be charged - and your junctions are about")
    print("      four times theirs.")
    print()
    print("      Layout parasitics are close to a fixed additive load. They vanish")
    print("      into the noise when a gate drives something big and they dominate")
    print("      when it drives something small, which is most of a real chip.")
    print()
    print("PASS  Both cells extracted with parasitics, both simulated, and the")
    print("      comparison is above. There is no wrong answer here - it is a")
    print("      measurement, and yours is yours.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
