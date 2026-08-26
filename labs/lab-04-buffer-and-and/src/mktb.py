#!/usr/bin/env python3
"""Write results/and2_tb.spice around whatever port order YOUR cell has.

Magic numbers a cell's ports in the order the labels were created, so the
`.subckt` line in your extracted netlist may list A, B, X, VPWR and VGND in a
different order from the reference. A testbench with the terminals in the wrong
order is a silent wrong answer, so this reads the order out of your netlist
instead of assuming it.
"""
from __future__ import annotations

import pathlib
import re
import sys

RESULTS = pathlib.Path(__file__).resolve().parents[1] / "results"

DECK = """* Lab 04 - the truth table of the AND gate you composed.
.lib $PDK_ROOT/sky130A/libs.tech/ngspice/sky130.lib.spice tt
.include {netlist}

Vdd VPWR 0 1.8
Va  A 0 PWL(0 0  1.0n 0  1.01n 0    2.0n 0    2.01n 1.8  3.0n 1.8)
Vb  B 0 PWL(0 0  1.0n 0  1.01n 1.8  2.0n 1.8  2.01n 0    3.0n 0   3.01n 1.8)
X1  {conns} my_and2
CL  X 0 2f

.tran 10p 4n
.meas tran x00 FIND v(X) AT=0.9n
.meas tran x01 FIND v(X) AT=1.9n
.meas tran x10 FIND v(X) AT=2.9n
.meas tran x11 FIND v(X) AT=3.9n
.end
"""

MAP = {"A": "A", "B": "B", "X": "X", "VPWR": "VPWR", "VGND": "0"}


def main() -> int:
    netlist = RESULTS / "my_and2.pex.spice"
    if not netlist.exists():
        sys.exit("results/my_and2.pex.spice is missing - run `make` first.")
    match = re.search(r"^\.subckt\s+my_and2\s+(.*)$", netlist.read_text(), re.M)
    if not match:
        sys.exit("No `.subckt my_and2` in the extracted netlist - did the cell save?")
    ports = match.group(1).split()
    missing = [p for p in MAP if p not in ports]
    if missing:
        sys.exit(
            f"Your my_and2 has no port called {', '.join(missing)}.\n"
            f"Its ports are: {' '.join(ports)}\n"
            "Label the missing shape and run `make` again."
        )
    conns = " ".join(MAP[p] for p in ports)
    (RESULTS / "and2_tb.spice").write_text(
        DECK.format(netlist="my_and2.pex.spice", conns=conns)
    )
    print(f"   testbench built for port order: {' '.join(ports)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
