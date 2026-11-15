#!/usr/bin/env python3
"""Write results/fo4.spice from spice/fo4.spice, wired for YOUR cell's port order.

spice/fo4.spice writes each my_inv instance with its nets in the reference
order A Y VPWR VGND. This copies the deck into results/ and rewrites those
lines in the order your extracted `.subckt my_inv` line uses (see ports.py).
"""
from __future__ import annotations

import pathlib

from ports import RESULTS, connect, my_inv_ports

DECK = pathlib.Path(__file__).resolve().parents[1] / "spice" / "fo4.spice"


def main() -> None:
    ports = my_inv_ports()
    lines = []
    for line in DECK.read_text().splitlines():
        fields = line.split()
        if fields and fields[0].startswith("X") and fields[-1] == "my_inv":
            line = f"{fields[0]} {connect(fields[1:-1], ports)} my_inv"
        lines.append(line)
    (RESULTS / "fo4.spice").write_text("\n".join(lines) + "\n")
    print(f"   wrote results/fo4.spice  (my_inv ports: {' '.join(ports)})")


if __name__ == "__main__":
    main()
