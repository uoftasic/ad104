# Lab 04 — A buffer and an AND gate

Writeup: [uoftasic.com/ad104 → Lab 04](https://uoftasic.com/ad104/labs/lab-04-buffer-and-and-overview.html)

Two blocks built from cells you already have: a buffer from two inverters, and an AND gate from a
NAND and an inverter. You wire the cells together and label the blocks' ports in Magic, without
drawing any new transistors. A third cell, `my_inv_gen`, is the same inverter with its two
transistors drawn by Magic's device generator.

## Run it

```bash
cd labs/lab-04-buffer-and-and
make cells        # (re)build mag/my_inv.mag and mag/my_nand2.mag
make scaffold     # two blocks, each with its two cells already placed
cd mag
magic -d X11 my_nand2 &
```

You open, wire, label and save the blocks in Magic, as the writeup describes. Then, from
`labs/lab-04-buffer-and-and`:

```bash
make layout       # DRC and LVS of both blocks, about 1.5 s
make              # the same, then the AND gate's truth table, about 10-15 s
make gen          # DRC and LVS of mag/my_inv_gen.mag
```

The full `make` took 10.3 and 13.4 seconds on two timed clean runs, and nearly all of that is
ngspice reading the SKY130 model library for the truth-table simulation. Use `make layout` while
you are wiring.

## Targets

| Command | What it does |
|---|---|
| `make` | DRC + LVS both blocks, then simulate the AND |
| `make layout` | just the DRC and LVS part, about 1.5 s |
| `make gen` | DRC + LVS the generated inverter, `mag/my_inv_gen.mag` |
| `make cells` | rebuild the two leaf cells |
| `make scaffold` | **throw your work away**, back to two placed cells |
| `make ref` / `make refcheck` | build and check the reference blocks and the reference generated inverter |
| `make clean` | delete `results/` |

## Files

| Path | What it is |
|---|---|
| `mag/my_inv.mag` | the Lab 03 reference inverter |
| `mag/my_nand2.mag` | the NAND, shipped finished |
| `mag/my_buf.mag`, `mag/my_and2.mag` | **your blocks** |
| `mag/my_inv_gen.mag`, `mag/sky130_fd_pr__*.mag` | **your generated inverter** and its two device cells, once you have saved them |
| `tcl/inv.tcl` | the Lab 03 inverter, so this lab stands alone |
| `tcl/nand2.tcl` | how the NAND was drawn, commented. Read it. |
| `tcl/scaffold.tcl` | the two blocks with their cells placed and nothing wired |
| `tcl/compose.tcl` | the reference blocks |
| `tcl/inv_gen.tcl` | the reference generated inverter, with the generator called from Tcl |
| `tcl/verify.tcl` | DRC both ways, extract, PEX-extract |
| `tcl/verify_gen.tcl` | DRC both ways and extract, for `make gen` |
| `spice/cells_sch.spice` | the schematic side of LVS, all four cells |
| `spice/swapped_sch.spice` | the NAND with A and B exchanged |
| `spice/my_inv_gen_sch.spice` | the inverter under the name `my_inv_gen` |
| `src/mktb.py` | builds the testbench around **your** netlist's port order, because Magic orders ports by when the labels were created |
| `src/check_gen.py` | the verdict for `make gen` |
| `solutions/README.md` | three decisions in the reference worth arguing about |
