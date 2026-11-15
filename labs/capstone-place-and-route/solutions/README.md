# The reference block

The reference block is `datapath_ref.mag`, which `make ref` regenerates from `tcl/route_ref.tcl`.

**Don't open it before you have routed yours.** When you do, `tcl/route_ref.tcl` is the more
useful file to read, because every rectangle in it has a comment saying where its coordinates
came from and which rule set its size.

## Five decisions in the reference

**1. Everything is routed on metal1.** Three nets are few enough that the band between the rails,
y = 0.38 to 2.34 µm, has room, and metal1 needs only one via type (`mcon`) at each end instead of
two. A real router would put some of this on metal2 and pay for the extra via, because it cannot
know there are only three nets. Try adding a fourth signal and see how quickly the band fills.

**2. Every metal1 pad is 0.29 µm across a 0.17 µm cut.** `met1.4` wants 0.03 µm of enclosure
everywhere and `met1.5` wants 0.06 µm on both sides of one axis; 0.29 leaves 0.06 on each side and
satisfies both on x, and it is the smallest number that does. Shrink one pad to 0.23 and re-run
`make layout` to see `met1.5` fire.

**3. The `D` connection takes its via 0.4 µm below the D label.** The obvious spot is 0.07 µm
from one of the flip-flop's internal metal1 straps, which breaks `met1.2`. The D pin's li shape
runs down to y = 0.715, so the via goes there. Finding somewhere else on the same pin to land
is the routing move you will make most often, and it is why routers keep a blockage map of every
cell.

**4. The block paints its own metal1 rails over the whole row.** They are electrically redundant:
the cells' own rails already abut into two continuous strips. They exist so that the *block* has
geometry of its own to hang a `VGND` label on. A label on a subcell's rail belongs to the subcell,
so without the block's own rails it would come out of extraction with no supply ports at all. To
see it, delete the two `p m1 -0.46 ...` rail lines in `tcl/route_ref.tcl`, then run `make ref`
and `make refcheck`: the `ports` line drops to `CLK D A B Y`, and netgen reports
`Top level cell failed pin matching` on a block that is otherwise perfect.
`git checkout tcl/route_ref.tcl solutions/` puts everything back.

**5. Two tap cells, one at each end, and none in the middle.** `LU.2` and `LU.3` ask for a tap
within 15 µm of every diffusion. The row is 14.26 µm wide, so two at the ends is comfortable, and
one in the middle would have shifted every coordinate in the file. A wider row needs taps spread
through it, and a real flow inserts them on a fixed pitch after placement.

## The failure to read first

Run `make scaffold` and then `make layout`, and read the output before you route anything. With
four cells placed and no wires, it prints:

```
      DRC, default rule set  0
      DRC, full rule set     32
      LVS                    Top level cell failed pin matching
```

The default rule set finds zero errors in that geometry and the full rule set finds thirty-two.
That pair of numbers is the most important thing in this lab, and it is the reason every lab
`make` that runs DRC in this course runs both rule sets and prints both counts.

## Compared with a place-and-route tool

You built four cells, three nets and one row in about ninety minutes. In
[DD103](https://uoftasic.com/dd103/), a tool hardens a whole design (place, tap, route, DRC, LVS,
GDS) in about a minute. It does nothing you haven't now done by hand; it just does it a hundred
thousand times, guided by a cost function, and it never forgets the taps.
