# SKY130 layer map

The layers this course uses, bottom to top, with the three names each one has: what you type in
Magic, what the GDS calls it, and what it is physically.

The GDS numbers are `layer/datatype`. They come from the `calma` lines in
`$PDK_ROOT/sky130A/libs.tech/magic/sky130A.tech`, and they are what you see in KLayout's layer
panel. The sheet resistances are the `resist` lines in the same file, converted from milliohms to
ohms per square.

| Magic | GDS | Physically | Sheet R |
|---|---|---|---|
| `nwell` | 64/20 | an n-type tub in the p-substrate | 950 Ω/□ |
| `pwell` | 64/44 (marker) | the p-substrate. SKY130 has no p-well mask; Magic draws one as a marker so it can reason about the body, and it does not become a real layer. | 4400 Ω/□ |
| `ndiff` | 65/20 + 93/44 | n+ silicon at the surface | 120 Ω/□ |
| `pdiff` | 65/20 + 94/20 | p+ silicon at the surface | 197 Ω/□ |
| `ntap` | 65/44 + 93/44 | n+ silicon **inside the n-well**: a handle on the well | 120 Ω/□ |
| `ptap` | 65/44 + 94/20 | p+ silicon in the substrate: a handle on the substrate | 197 Ω/□ |
| `poly` | 66/20 | polysilicon on the thin gate oxide | 48.2 Ω/□ |
| `pfethvt` | 78/44 | the HVTP implant, which makes a PMOS high-threshold | — |
| `pc` (poly contact) | 66/44 + 95/20 | a tungsten plug from poly to li, plus the NPC blocking mask | — |
| `ndc` / `pdc` / `ntapc` / `ptapc` | 66/44 | the same plug, from silicon to li | — |
| `li` | 67/20 | local interconnect | **12.8 Ω/□** |
| `mcon` | 67/44 | plug from li to metal1 | — |
| `m1` | 68/20 | metal1 | **0.125 Ω/□** |
| `via1` | 68/44 | plug from metal1 to metal2 | — |
| `m2` | 69/20 | metal2 | 0.125 Ω/□ |
| `via2` / `m3` | 69/44 / 70/20 | and upward, to metal5 | |

## Reading the table

**Diffusion and tap are the same GDS layer.** `diff` is 65/20 and `tap` is 65/44: the same mask
with a different datatype. What makes one of them n-type and the other p-type is which implant
mask (`nsdm` 93/44 or `psdm` 94/20) is over it. A `ptap` and a `pdiff` are physically identical; the only difference is
that one sits in the substrate and the other in an n-well. That is why the tap
rules and the diffusion rules look so similar.

**li is a hundred times more resistive than metal1.** 12.8 Ω/□ against 0.125. A 10 µm li wire
0.17 µm wide is 59 squares, so about **750 Ω**. The same wire in metal1 is 7 Ω. That is why li
is called *local* interconnect: it gets you from a transistor to the wire, and it is not meant to
be the wire.

**Poly is a poor conductor.** 48.2 Ω/□. It is the gate, and it can be used as a short wire inside a
cell, but it is never used for routing.

## The contact ladder

There is exactly one legal route up:

```
poly ───┐
        ├─ licon1 (66/44) ─ li1 (67/20) ─ mcon (67/44) ─ met1 (68/20) ─ via1 ─ met2 ─ ...
diff ───┘
```

You cannot connect poly to metal1. You cannot connect diffusion to metal2.
Every jump is a plug of a fixed size with enclosure rules on both ends.

## Implant masks

`nsdm` (93/44) and `psdm` (94/20) decide whether a piece of active silicon is n+ or p+. In Magic
you never paint them directly: you paint `ndiff` or `ptap`, and Magic generates the right implant
when it writes GDS. You will still see them named in DRC messages:

```
NSDM width < 0.40um (diff/tap.5)
```

You also see them in the `MASKHINTS_NSDM` properties of the foundry's cells, which is where the
library records hand-tuned implant shapes that Magic's automatic generation would not have
produced.

`hvtp` (78/44) is the exception you *do* paint, as `pfethvt`, because which
threshold flavour your PMOS is cannot be derived from anything else.

## Viewing layers in KLayout

```bash
klayout -nn $PDK_ROOT/sky130A/libs.tech/klayout/tech/sky130A.lyt yourfile.gds
```

The layer panel on the right lists every layer present with its numbers, and clicking the eye
icon hides a layer. Hiding everything above `met1` is the fastest way to see the standard-cell
rows underneath a routed block.

![The capstone block as GDS](../assets/img/ad104-klayout-datapath.png)

*The capstone's GDS in KLayout. The cell tree is on the left, with `datapath_ref` and the four
library cells and the tap cell under it, and the layer list on the right has the numbers from
the table above.*
