# Routing by hand

The capstone asks you to route three nets, and three are enough to meet every basic idea in
interconnect. This page explains those ideas; you route the nets yourself in the
[capstone](../labs/capstone-place-and-route-overview.md).

![Four cells and three wires](../assets/img/ad104-magic-datapath.png)

*The capstone block with its subcells collapsed, so the cells are outlines and your routing is the
only real geometry on screen. Left to right: a tap cell, the flip-flop, two AND gates, the
buffer, and another tap. The pink metal1 shapes and the boxed contacts are the entire hand-routed
part.*

## The layer stack as a routing problem

You can't connect any layer to any other. There is exactly one ladder:

```
poly ──licon1──┐
               ├── li1 ──mcon── met1 ──via1── met2 ──via2── met3 ...
diffusion ─licon1─┘
```

Every rung is a plug of a fixed size, and each plug has enclosure rules on both sides. So a
connection from a cell pin to a wire two microns away is:

1. an `mcon` on the pin (li1 → metal1), exactly 0.17 µm square
2. a metal1 pad around it, surrounding the cut by 0.03 µm everywhere and by 0.06 µm on both
   sides of one axis (`met1.4`, `met1.5`)
3. metal1 from that pad to the next one
4. another pad and another `mcon` at the far end

The capstone's pads are 0.29 µm wide for a 0.17 µm cut. That is 0.06 µm on each side, which
satisfies `met1.5` on the x axis, and it is the smallest width that works.

## Which layer to route on

**li1** is the cell's own pin layer, so a li wire needs no via at either end. It is also about
**12.8 Ω per square**, against metal1's **0.125**: a hundred times worse. Use it for a wire short
enough that you can see both ends. Lab 04's blocks route on li because the wire is 2.4 µm long
and saving the vias is worth more than the resistance costs.

**metal1** is where real local routing goes. In this library the cells use metal1 only for their
rails, with one exception. The band between the rails is free space above every cell **except the
flip-flop**, which has internal metal1 straps of its own.

**metal2 and up** are not used by `sky130_fd_sc_hd` at all. If you need to cross the row, go up.

## The routing band

The rails occupy y = −0.24 to 0.24 and y = 2.48 to 2.96, and metal1 spacing is 0.14 µm. So any
metal1 wire that is not part of the supply has to stay between:

```
y = 0.38   and   y = 2.34
```

That leaves 1.96 µm of vertical space for every signal in the row. In the capstone it is enough.
In a real block it is not, which is why routers alternate directions.

## Why routers alternate directions

The convention is that each metal layer runs in one direction only: metal1 vertical, metal2
horizontal, metal3 vertical, and so on.

It looks like bureaucracy, and it is the only thing that makes routing tractable. Two wires on the same layer
going the same way compete for the same track; two wires on adjacent layers at right angles cross
without interacting. Once every layer has a direction, "is there room?" becomes a question about
a grid of tracks instead of a question about geometry, and a computer can answer it.

Your three nets are all on metal1 because there are only three of them, and at this scale you
can break the rule. While you route them, notice that you can keep the whole picture in your
head, and that this would stop being true somewhere around ten nets.

## Metal already inside a cell

Before you put metal1 across a cell, check what metal1 it already has, by reading the
`<< metal1 >>` section of its `.mag` file. On the workbench image, `and2_0` has 16 metal1
rectangles and `buf_1` has 12, all of them in the rails. `dfxtp_1` has 74, including two long
horizontal straps across the middle of the cell. Those straps are why the capstone's `D`
connection cannot take its via at the D label: a pad there would sit 0.07 µm from a strap and
break `met1.2`.

The D pin's li shape extends down to y = 0.715, clear of the straps, so the via goes down there
instead. **Finding another place on the same pin to land** is the routing move you will use most,
and doing it once by hand shows you what the tool is doing when it does the same.

## Pin shapes

A cell's pin is a rectangle of li, and often several rectangles in different places on the same
net. `buf_1` publishes its output `X` at three different heights. Any of them is a legal place to
land, so pick the one your wire can reach.

The coordinates are in the cell's `.mag` file, as `flabel` lines. This is `and2_0`'s output `X`:

```
flabel locali s 397 425 431 459 0 FreeSans 340 0 0 0 X
port 7 nsew signal output
```

The units are 0.005 µm again, so that pin is x = 1.985–2.155, y = 2.125–2.295, relative to the
cell's origin. Add the x you placed the cell at, and you know where to put the `mcon`.

## The routing loop

The capstone turns this page into a step-by-step procedure: find both pins in absolute
coordinates, put an `mcon` and a pad on each, join them inside the band, then check. Two checks
matter, and they catch different things. DRC, under both rule sets, catches spacing and enclosure
mistakes and the missing tap cells. LVS catches a wire that does not quite land.
