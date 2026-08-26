#!/usr/bin/env python3
"""Write results/timing.spice around YOUR block's port order.

Also reads the flip-flop's setup time straight out of the same Liberty file
the digital track synthesises against, because f_max is not a delay - it is a
delay plus a setup time, and the setup time is not something you can simulate
out of your own layout.
"""
from __future__ import annotations

import os
import pathlib
import re
import sys

RESULTS = pathlib.Path(__file__).resolve().parents[1] / "results"
PDK_ROOT = os.environ.get("PDK_ROOT", "/foss/pdks")
LIB = (
    pathlib.Path(PDK_ROOT)
    / "sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"
)

DECK = """* Capstone - how long the clock edge takes to reach Y.
*
* CLK rises, the flip-flop drives Q, Q walks through two AND gates and a
* buffer, and Y moves. Everything in this deck is your extracted layout with
* every parasitic capacitance Magic could find.
.lib $PDK_ROOT/sky130A/libs.tech/ngspice/sky130.lib.spice tt
.include datapath.pex.spice

Vdd  VPWR 0 1.8
Va   A 0 1.8
Vb   B 0 1.8
Vd   D 0 1.8
Vclk CLK 0 PULSE(0 1.8 1n 50p 50p 2n 4n)
X1   {conns} datapath
CL   Y 0 5f

.tran 1p 6n
.meas tran t_clk_y TRIG v(CLK) VAL=0.9 RISE=1 TARG v(Y) VAL=0.9 RISE=1
.end
"""

MAP = {"CLK": "CLK", "D": "D", "A": "A", "B": "B", "Y": "Y", "VGND": "0", "VPWR": "VPWR"}


def setup_time() -> float | None:
    """The worst-case D-to-CLK setup constraint of sky130_fd_sc_hd__dfxtp_1, in ns."""
    if not LIB.exists():
        return None
    text = LIB.read_text()
    start = text.index('cell ("sky130_fd_sc_hd__dfxtp_1")')
    end = text.index('cell ("', start + 10)
    block = text[start:end]
    pin_d = block.index('pin ("D")')
    section = block[pin_d : pin_d + 4000]
    worst = None
    for kind in ("rise_constraint", "fall_constraint"):
        m = re.search(kind + r'\s*\("[^"]+"\)\s*\{.*?values\("([^"]+)"', section, re.S)
        if m:
            first = float(m.group(1).split(",")[0])
            worst = first if worst is None else max(worst, first)
    return worst


def main() -> int:
    netlist = RESULTS / "datapath.pex.spice"
    if not netlist.exists():
        sys.exit("results/datapath.pex.spice is missing - run `make` first.")
    m = re.search(r"^\.subckt\s+datapath\s+(.*)$", netlist.read_text(), re.M)
    if not m:
        sys.exit("No `.subckt datapath` in the extracted netlist.")
    ports = m.group(1).split()
    missing = [p for p in MAP if p not in ports]
    if missing:
        sys.exit(
            f"Your datapath has no port called {', '.join(missing)}.\n"
            f"Its ports are: {' '.join(ports)}\n"
            "Every one of CLK D A B Y VGND VPWR has to be a label on your top cell."
        )
    (RESULTS / "timing.spice").write_text(DECK.format(conns=" ".join(MAP[p] for p in ports)))
    ts = setup_time()
    if ts is not None:
        (RESULTS / "setup.txt").write_text(f"{ts}\n")
    print(f"   testbench built for port order: {' '.join(ports)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
