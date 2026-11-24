# Lab 03: Draw an inverter

Writeup: [uoftasic.com/ad104 → Lab 03](https://uoftasic.com/ad104/labs/lab-03-draw-an-inverter-overview.html)

You draw a CMOS inverter in Magic, starting from a frame that already has the wells, rails and
taps, and keep going until the cell is DRC clean under both rule sets and netgen matches it to the
schematic.

## Run it

```bash
cd labs/lab-03-draw-an-inverter
make scaffold            # lay down the frame (also: start over)
cd mag
magic -d X11 my_inv &    # open it in Magic, and draw there
cd ..
make                     # check what you have, about a second
```

You draw, check and extract in Magic, and run netgen yourself from `mag/`; the writeup takes you
through it. `make` tells you in words what it found and what to fix next. Save in Magic
(`File → Save...`, then `write`) before every `make`, because the checker reads `mag/my_inv.mag`
from disk and never sees edits you haven't saved.

## Targets

| Command | What it does |
|---|---|
| `make` | DRC both ways, extract, LVS, verdict |
| `make scaffold` | **throw your cell away**, back to the empty frame |
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
| `tcl/verify_ref.tcl` | the same checks on `solutions/inv_ref.mag`, for `make refcheck` |
| `src/check.py` | reads the Magic and netgen reports and prints the verdict |
| `spice/my_inv_sch.spice` | the schematic side of LVS |
| `solutions/inv_ref.mag` | the finished reference. Open it after yours works. |
