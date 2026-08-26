# Lab 04 — A buffer and an AND gate

Writeup: [uoftasic.com/ad104 → Lab 04](https://uoftasic.com/ad104/#/labs/lab-04-buffer-and-and-overview)

Two more cells and **not one new transistor**. A buffer is two of your
inverters; an AND gate is a NAND and one of your inverters.

## Run it

```bash
cd labs/lab-04-buffer-and-and
make cells        # (re)build mag/my_inv.mag and mag/my_nand2.mag
make scaffold     # two blocks, each with its two cells already placed
make edit CELL=my_buf
make              # about a minute
```

**53, 63 and 74 seconds on three timed clean runs**, nearly all of it ngspice
reading the SKY130 model library for the truth-table simulation. `make layout`
does the DRC and LVS part alone in **1.9 s**, and that is the loop you want
while you are wiring.

## What PASS looks like

```
  block      DRC default  DRC full   LVS                       contains
  --------------------------------   ------------------------  ----------------
  ok my_buf            0         0   match                     my_inv, my_inv
  ok my_and2           0         0   match                     my_inv, my_nand2

  THE AND GATE, SIMULATED

      ok  A=0  B=0   X = 0.000000 V   (expected 0.0)
      ok  A=0  B=1   X = 0.000000 V   (expected 0.0)
      ok  A=1  B=0   X = 0.000001 V   (expected 0.0)
      ok  A=1  B=1   X = 1.800000 V   (expected 1.8)
```

## The one to run on purpose

```bash
make swapped
```

LVSes the NAND against a netlist with `A` and `B` exchanged, and produces
netgen's most confusing message: **`Netlists match uniquely` together with
`failed pin matching`**. The topology is right and two labels are on the wrong
shapes. A NAND is symmetric in its inputs, so nothing else in the flow will
ever notice — and the timing model will be wrong.

## Targets

| Command | What it does |
|---|---|
| `make` | DRC + LVS both blocks, then simulate the AND |
| `make layout` | just the DRC and LVS part, about 2 s |
| `make edit CELL=my_and2` | open a block in Magic |
| `make cells` | rebuild the two leaf cells |
| `make scaffold` | **throw your work away**, back to two placed cells |
| `make ref` / `make refcheck` | build and check the reference blocks |
| `make swapped` | the pin-matching failure, on purpose |
| `make sim` | just the four measured rows |
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
| `src/mktb.py` | builds the testbench around **your** netlist's port order |
| `solutions/README.md` | three decisions in the reference worth arguing about |

## Why `src/mktb.py` exists

Magic numbers a cell's ports in the order the labels were created, so if you
named `X` before `A` your `.subckt` line differs from the reference's. A
testbench with the terminals in the wrong order is a silent wrong answer, not
an error — so the deck is generated from your own netlist's port list instead
of assuming one.
