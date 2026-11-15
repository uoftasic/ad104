# Lab 03 — Draw an inverter

Writeup: [uoftasic.com/ad104 → Lab 03](https://uoftasic.com/ad104/labs/lab-03-draw-an-inverter-overview.html)

You draw a CMOS inverter in Magic, starting from a frame that already has the wells, rails and
taps, until it is DRC clean under both rule sets and netgen matches it to the schematic.

## Run it

```bash
cd labs/lab-03-draw-an-inverter
make scaffold     # lay down the frame (also: start over)
make edit         # open it in Magic
make              # check what you have, about 1.1 s
```

`make` reports in words what it found and what to fix next. Save in Magic before every `make`:
the checker reads `mag/my_inv.mag` from disk.

## Targets

| Command | What it does |
|---|---|
| `make` | DRC both ways, extract, LVS, verdict |
| `make edit` | open your cell in Magic |
| `make scaffold` | **throw your cell away**, back to the empty frame |
| `make netlist` | print what Magic extracted from your geometry |
| `make ref` | rebuild `solutions/inv_ref.mag` from `tcl/inverter.tcl` |
| `make refcheck` | run every check against the reference instead of yours |
| `make clean` | delete `results/` |

## Files

| Path | What it is |
|---|---|
| `mag/my_inv.mag` | **your cell** |
| `tcl/frame.tcl` | the frame: wells, rails, taps. What `make scaffold` runs. |
| `tcl/inverter.tcl` | the reference cell, drawn command by command with the reason for every number. Read it after yours passes. |
| `tcl/verify.tcl` | DRC, extract and PEX-extract whatever is in `mag/` |
| `spice/my_inv_sch.spice` | the schematic side of LVS |
| `solutions/inv_ref.mag` | the finished reference. Open it after yours works. |
