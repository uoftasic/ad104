# Lab 05 — What it costs

Writeup: [uoftasic.com/ad104 → Lab 05](https://uoftasic.com/ad104/labs/lab-05-what-it-costs-overview.html)

This package extracts the Lab 03 inverter and the foundry's `inv_1` with every parasitic
capacitance kept, simulates both, and prints a table comparing their area, junction area,
capacitance and delay. In the writeup you measure both cells and extract them in Magic yourself
first; `make` then runs the same extraction and the simulations.

## Run it

```bash
cd labs/lab-05-what-it-costs/mag
magic -d X11 my_inv &      # measure and extract, as the writeup describes
cd ..
make
```

A clean run takes about half a minute (27 to 39 s on the seven we timed), and nearly all of that
time goes into the two ngspice runs: the fan-out deck and the two 31-stage ring oscillators.

By default it compares the reference Lab 03 inverter, in `mag/my_inv.mag`, with the foundry's.
To compare your own cell instead, copy it in with `make mine` and then run `make`:

```bash
make mine MAG=../lab-03-draw-an-inverter/mag/my_inv.mag
make
```

A cell drawn by following Lab 03 lists its ports as `VGND VPWR A Y`, and the reference lists them
as `A Y VPWR VGND`, so both decks are wired around the order in your extracted netlist rather
than assuming one. `git checkout mag/my_inv.mag` puts the reference cell back.

## Targets

| Command | What it does |
|---|---|
| `make` | extract both cells with parasitics, simulate both, print the table |
| `make mine MAG=...` | copy your own Lab 03 cell in and compare that |
| `make table` | re-print from results already on disk, instantly |
| `make clean` | delete `results/` |

## Files

| Path | What it is |
|---|---|
| `mag/my_inv.mag` | the cell being compared. `make mine` replaces it. |
| `tcl/pex.tcl` | extracts both cells with `ext2spice cthresh 0` |
| `spice/fo4.spice` | both cells driving four copies of themselves, in one deck |
| `src/mkfo4.py` | copies that deck into `results/`, wired for your cell's port order |
| `src/mkring.py` | writes two 31-stage ring oscillators |
| `src/ports.py` | reads your cell's port order out of its extracted netlist, for both decks |
| `src/check.py` | reads everything and prints the comparison |
