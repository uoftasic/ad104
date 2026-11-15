# Lab 01: Open a cell you did not draw

Writeup: [uoftasic.com/ad104 → Lab 01](https://uoftasic.com/ad104/labs/lab-01-open-the-cell-overview.html)

This package loads the foundry's own inverter, `sky130_fd_sc_hd__inv_1`, into Magic, checks it
under both DRC rule sets, extracts it, and runs LVS against the foundry's netlist.

## Run it

```bash
cd labs/lab-01-open-the-cell
make
```

You need no environment setup first. The `Makefile` sets `PDK=sky130A` itself, so this
runs in a bare container even if `.designinit` failed. It takes about 1.5 seconds (1.35, 1.46 and
1.60 s on three timed clean runs) and ends in `PASS`. The full rule set reports three violations
on the foundry's cell, which is what it should report, and the writeup explains why.

## Targets

| Command | What it does |
|---|---|
| `make` | load, DRC both ways, extract, LVS, verdict |
| `make gui` | open the cell in Magic (`make edit` does the same) |
| `make klayout` | open the whole library GDS in KLayout |
| `make netlist` | print the netlist Magic extracted from the geometry |
| `make clean` | delete `results/` |

## Files

| Path | What it is |
|---|---|
| `.magicrc` | loads SKY130 into Magic |
| `tcl/inspect.tcl` | what `make` runs: the same commands you would type |
| `src/check.py` | reads the results and prints the verdict |

There is nothing to edit in this lab. The cell is the foundry's, so what the lab checks is your
toolchain and not a layout of your own.
