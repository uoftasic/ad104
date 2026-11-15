# Lab 04 — A buffer and an AND gate

Writeup: [uoftasic.com/ad104 → Lab 04](https://uoftasic.com/ad104/labs/lab-04-buffer-and-and-overview.html)

Two blocks built from cells you already have: a buffer from two inverters, and an AND gate from a
NAND and an inverter. Your job is to wire the cells together and label the blocks' ports, and
you won't draw any new transistors.

## Run it

```bash
cd labs/lab-04-buffer-and-and
make cells        # (re)build mag/my_inv.mag and mag/my_nand2.mag
make scaffold     # two blocks, each with its two cells already placed
make edit CELL=my_buf
make              # about 10-15 s
```

The full `make` took 10.3 and 13.4 seconds on two timed clean runs, and nearly all of that is
ngspice reading the SKY130 model library for the truth-table simulation. `make layout` runs only
the DRC and LVS part, which takes about 1.5 s, so use it while you are wiring.

## Targets

| Command | What it does |
|---|---|
| `make` | DRC + LVS both blocks, then simulate the AND |
| `make layout` | just the DRC and LVS part, about 1.5 s |
| `make sim` | just the four measured rows |
| `make edit CELL=my_and2` | open a block in Magic (`CELL` defaults to `my_buf`) |
| `make cells` | rebuild the two leaf cells |
| `make scaffold` | **throw your work away**, back to two placed cells |
| `make ref` / `make refcheck` | build and check the reference blocks |
| `make swapped` | LVS the NAND against a netlist with `A` and `B` exchanged |
| `make clean` | delete `results/` |

## Files

| Path | What it is |
|---|---|
| `mag/my_inv.mag` | the Lab 03 reference inverter |
| `mag/my_nand2.mag` | the NAND, shipped finished |
| `mag/my_buf.mag`, `mag/my_and2.mag` | **your blocks** |
| `tcl/inv.tcl` | the Lab 03 inverter, so this lab stands alone |
| `tcl/nand2.tcl` | how the NAND was drawn, commented. Read it. |
| `tcl/scaffold.tcl` | the two blocks with their cells placed and nothing wired |
| `tcl/compose.tcl` | the reference blocks |
| `tcl/verify.tcl` | DRC both ways, extract, PEX-extract |
| `spice/cells_sch.spice` | the schematic side of LVS, all four cells |
| `spice/swapped_sch.spice` | the NAND with A and B exchanged |
| `src/mktb.py` | builds the testbench around **your** netlist's port order, because Magic orders ports by when the labels were created |
| `solutions/README.md` | three decisions in the reference worth arguing about |
