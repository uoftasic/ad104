# Routing by hand

Three nets. That is what the capstone asks you to route, and it is enough to
meet every idea in interconnect.

![Four cells and three wires](../assets/img/ad104-magic-datapath.png)

*The capstone block with its subcells collapsed, so the cells are outlines and
your routing is the only real geometry on screen. Left to right: a tap cell,
the flip-flop, two AND gates, the buffer, another tap. The pink metal1 shapes
and the boxed contacts are the entire hand-routed part.*

## The layer stack, as a routing problem

You cannot connect anything to anything. There is exactly one ladder:

```
poly ──licon1──┐
               ├── li1 ──mcon── met1 ──via1── met2 ──via2── met3 ...
diffusion ─licon1─┘
```

Every rung is a plug of a fixed size, and each plug has enclosure rules on both
sides. So a connection from a cell pin to a wire two microns away is:

1. `mcon` on the pin (li1 → metal1) — 0.17 µm square, exactly
2. a metal1 pad around it, surrounding the cut by 0.03 µm everywhere and
   0.06 µm on both sides of one axis (`met1.4`, `met1.5`)
3. metal1 from that pad to the next one
4. another pad and another `mcon` at the far end

The capstone's pads are 0.29 µm wide for a 0.17 µm cut, which is 0.06 on each
side and satisfies `met1.5` on the x axis. That is not a coincidence; it is
the smallest number that works.

## Which layer to route on

**li1** is the cell's own pin layer, so a li wire needs no via at either end.
It is also about **12.8 Ω per square** against metal1's **0.125** — a hundred
times worse. Use it for a wire you can see the ends of. Lab 04's blocks route
on li because the wire is 2.4 µm long and the via saving is worth more than
the resistance.

**metal1** is where real local routing lives. In this library the cells use
metal1 only for their rails — mostly. The band between the rails is free
airspace above every cell **except the flip-flop**, which has internal metal1
straps of its own.

**metal2 and up** are completely unused by `sky130_fd_sc_hd`. If you need to
cross the row, go up.

## The band you are allowed to route in

The rails occupy y = −0.24 to 0.24 and y = 2.48 to 2.96. Metal1 spacing is
0.14 µm. So any metal1 wire you draw that is not part of the supply has to
live between:

```
y = 0.38   and   y = 2.34
```

That is 1.96 µm of vertical space for every signal in the row. In the capstone
it is enough. In a real block it is not, which is why routers alternate
directions.

## Why routers alternate directions

The convention is that each metal layer runs in one direction only: metal1
vertical, metal2 horizontal, metal3 vertical, and so on.

It looks like bureaucracy and it is the only thing that makes routing
tractable. Two wires on the same layer going the same way compete for the same
track; two wires on adjacent layers going at right angles cross without
interacting. Once you commit to alternating, "is there room?" becomes a
question about a grid of tracks rather than a question about geometry, and a
computer can answer it.

Your three nets are all on metal1 because there are three of them. You are
allowed to break the rule at this scale. Notice while you are doing it that
you are able to keep the whole picture in your head, and that this stops being
true somewhere around ten nets.

## Reading a cell before routing over it

Before you put metal1 across a cell, look at what it already has:

```bash
awk '/<< metal1 >>/,/<< labels >>/' \
  $PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/mag/sky130_fd_sc_hd__dfxtp_1.mag
```

For `and2_0` and `buf_1` you get eight rectangles, all of them rail. For
`dfxtp_1` you get forty-odd, including two long horizontal straps across the
middle of the cell. Those straps are why the capstone's `D` connection cannot
take its via at the D label: a pad there would sit 0.07 µm from a strap and
break `met1.2`.

The D pin's li shape extends down to y = 0.715, well clear of everything, so
the via goes down there instead. **Finding somewhere else on the same pin to
land** is the routing move you will use most often, and it is worth doing once
by hand to know that it is what the tool is doing too.

## Pins are shapes, not points

A cell's pin is a rectangle of li — often several, in different places, all on
the same net. `buf_1` publishes its output `X` at three different heights.
Any of them is a legal place to land, so pick the one the wire can reach.

The coordinates are in the `.mag` file, as `flabel` lines:

```
flabel locali s 397 425 431 459 0 FreeSans 340 0 0 0 X
port 7 nsew signal output
```

Units of 0.005 µm again, so that pin is x = 1.985–2.155, y = 2.125–2.295
relative to the cell's origin. Add the x you placed the cell at, and you have
where to put the `mcon`.

## The checklist

1. Work out where both pins are, in absolute coordinates.
2. Put an `mcon` on each, 0.17 µm square, inside the li shape.
3. Put a metal1 pad around each, at least 0.29 µm on one axis.
4. Join them with metal1, staying between y = 0.38 and y = 2.34.
5. `drc check`. Fix by rule.
6. `drc style drc(full)`, check again. This is where missing tap cells appear.
7. Extract, LVS. This is where a wire that does not quite land appears.

Steps 5 and 7 catch different things and neither one catches the other's.
