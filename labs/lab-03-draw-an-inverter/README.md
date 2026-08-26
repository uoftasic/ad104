# Lab 03 — Draw an inverter

Writeup: [uoftasic.com/ad104 → Lab 03](https://uoftasic.com/ad104/#/labs/lab-03-draw-an-inverter-overview)

Two transistors, one shared gate, DRC clean under both rule sets, and proved
by netgen to be the circuit you meant.

**Wn = 0.65 µm, Wp = 1.00 µm, L = 0.15 µm** — the foundry's own `inv_1`
numbers, so that Lab 05 can compare the two cells with the transistors held
identical.

## Run it

```bash
cd labs/lab-03-draw-an-inverter
make scaffold     # lay down the frame (also: start over)
make edit         # open it in Magic
make              # check what you have, about 1.1 s
```

`make` reports in words. On the bare scaffold:

```
FAIL  No transistors at all. A transistor is the place where a poly stripe
      crosses a diffusion. If Magic sees no crossing, either the poly does
      not overlap the diffusion, or one of them is not the layer you think
      it is - check the layer name in the title bar as you paint.
```

Fix one thing, run `make` again. That loop is the job.

## What PASS looks like

```
      transistors            2   (1 n, 1 p)
        X0   sky130_fd_pr__nfet_01v8          W=0.65  L=0.15
        X1   sky130_fd_pr__pfet_01v8_hvt      W=1  L=0.15

      ports                  A Y VPWR VGND

      DRC, default rule set  0
      DRC, full rule set     0

      LVS                    Circuits match uniquely.
```

Note `_hvt` on the PMOS. If yours says `sky130_fd_pr__pfet_01v8` you have
built the wrong transistor, DRC will never mention it, and the checker will
tell you what to paint.

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
| `tcl/inverter.tcl` | the reference cell, drawn command by command with the reason for every number |
| `tcl/verify.tcl` | DRC, extract and PEX-extract whatever is in `mag/` |
| `spice/my_inv_sch.spice` | the schematic side of LVS |
| `solutions/inv_ref.mag` | the finished reference. Open it after yours works. |

`tcl/inverter.tcl` is the most useful file in this package and it is not a
diff — it is the cell built one command at a time, with a comment on each line
saying which rule set the number. Read it **after** yours passes.
