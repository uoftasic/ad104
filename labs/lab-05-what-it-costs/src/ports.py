"""Wire my_inv into a deck in the port order YOUR extracted netlist uses.

Magic numbers a cell's ports in the order the labels were created. The
reference cell in mag/my_inv.mag lists them as A Y VPWR VGND, but a cell drawn
by following Lab 03 lists them as VGND VPWR A Y, because the frame it started
from already had VGND and VPWR labelled. A deck that connected the terminals in
the wrong order would simulate the wrong circuit without raising any error, so
both decks read the order out of results/my_inv.pex.spice instead of assuming
it. Lab 04's src/mktb.py does the same for the AND gate.
"""
from __future__ import annotations

import pathlib
import re
import sys

RESULTS = pathlib.Path(__file__).resolve().parents[1] / "results"
REFERENCE_ORDER = ("A", "Y", "VPWR", "VGND")


def my_inv_ports() -> list[str]:
    """The port names on the `.subckt my_inv` line, in order."""
    netlist = RESULTS / "my_inv.pex.spice"
    if not netlist.exists():
        sys.exit("results/my_inv.pex.spice is missing - extraction did not run.")
    match = re.search(r"^\.subckt\s+my_inv\s+(.*)$", netlist.read_text(), re.M)
    if not match:
        sys.exit("No `.subckt my_inv` in results/my_inv.pex.spice - read results/magic.log")
    ports = match.group(1).split()
    if sorted(ports) != sorted(REFERENCE_ORDER):
        sys.exit(
            f"my_inv has the ports {' '.join(ports)}, and it needs exactly "
            f"{' '.join(REFERENCE_ORDER)}.\n"
            "Label the missing shape in Lab 03, then `make mine` and `make` again."
        )
    return ports


def connect(nets: list[str], ports: list[str]) -> str:
    """Take nets listed in the order A Y VPWR VGND and return them in `ports` order."""
    by_name = dict(zip(REFERENCE_ORDER, nets))
    return " ".join(by_name[p] for p in ports)
