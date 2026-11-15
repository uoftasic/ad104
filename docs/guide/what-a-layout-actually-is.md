# What a layout is

A schematic is a claim about connectivity. A layout is a **set of instructions for a machine
that prints patterns of light** onto a wafer. This page makes that concrete: how a wafer is
made, which layers you draw, and where the transistor is in a drawing that never mentions one.

## How a chip is printed

Fabricating a wafer is a loop, repeated about seventy times. Coat the wafer in something. Shine
light through a mask so that the mask's pattern lands on the coating. Wash away the parts that
were lit, or the parts that were not. Then do something to whatever is now exposed: implant ions
into it, grow an oxide on it, etch it away, or plate metal into it. Strip the coating and go
round again with the next mask.

A **layout is the drawing on those masks**. Every rectangle you paint in Magic ends up as a hole
or a blob on a piece of quartz that light goes through.

That has two consequences that are easy to say and take a while to feel:

- **There is no wire layer and no transistor layer.** There is a layer where the silicon was
  doped n-type and a layer where polysilicon was deposited, and where they cross you get a
  transistor. Nobody drew a transistor. They drew two rectangles that overlap.
- **Everything is a rectangle, and every rectangle has a minimum size.** The light has a
  wavelength, the etch spreads, and the wafer is not perfectly flat. The design rules are the
  foundry telling you what they can print with acceptable yield.

## The layers, bottom to top

SKY130 has about 40 mask layers, and this course uses ten of them. Physically they stack in this
order, and the order explains most of the rules:

| Magic layer | On the wafer | What it is for |
|---|---|---|
| `nwell` | a deep n-type tub in the p-substrate | somewhere to put PMOS |
| `ndiff` / `pdiff` | heavily doped silicon at the surface | the source and drain of a transistor, and the wire between them |
| `ptap` / `ntap` | doped silicon of the *same* type as the well underneath | a handle to hold the well at a known voltage |
| `poly` | polysilicon deposited on a very thin oxide | the **gate**. Where it crosses diffusion you get a transistor. |
| `licon1` (`ndc`/`pdc`/`pc` in Magic) | a tungsten plug | the only way up from silicon or poly |
| `li1` (`li`) | a thin local-interconnect layer | short wiring inside a cell |
| `mcon` | a plug from li1 to metal1 | the only way up from li |
| `met1` … `met5` | aluminium/copper wiring | wires |
| `via1` … `via4` | plugs between metal layers | the only way between metals |

The pattern is rigid and worth memorising: **conductor, plug, conductor, plug, conductor.** You
cannot connect metal1 to poly directly. You go poly → `licon1` → li1 → `mcon` → metal1. Half of a
beginner's DRC errors come from trying to skip a step.

![The inverter, layer by layer](../assets/img/ad104-magic-my-inv.png)

*Read this bottom to top. Purple at the very bottom and very top: the metal1 supply rails. The
orange hatch just above the lower rail and the green block above that: the p-tap and the NMOS
n-diffusion. The red stripe running the full height: one strip of polysilicon, the gate of both
transistors. The pale-blue vertical runs: local interconnect. The boxed X's: contacts, every one
of them 0.17 µm square because that is the only size the process makes.*

## Where the transistor is

There is no object called "transistor" anywhere in that picture. There is:

- a strip of green n-diffusion, 0.65 µm tall,
- a red poly stripe, 0.15 µm wide, crossing it,
- and a contact on either side.

The poly sits on a few nanometres of oxide over the silicon. A voltage on the poly pulls electrons
to the surface of the silicon underneath, which joins the two diffusion regions into one
conducting channel. **The channel is the part of the diffusion that the poly covers.**

So:

- **$W$ is the height of the diffusion where the poly crosses it.** A wider channel carries more
  current.
- **$L$ is the width of the poly stripe where it crosses.** A longer channel carries less current.

You never type `W=0.65` in this course. In Lab 03 you draw a rectangle 0.65 µm tall, and Magic
reads `w=0.65` back out of it. That round trip, where you draw a shape and a tool tells you the
device parameter, is when layout stops being abstract.

## Diffusion as a wire, and tying the wells

**Diffusion is also a wire.** The strip of n-diffusion between two poly gates is a conductor.
That is why two transistors in series can share it and need no contact between them, which you
will see in the NAND gate in Lab 04. It is a poor wire, resistive and heavy with junction
capacitance, so nobody routes with it further than the next transistor.

**The wells need tying to a supply.** The p-substrate under your NMOS and the n-well under your
PMOS are the *bodies* of your transistors, and the body terminal is real. If nothing ties them to
a supply they float and the threshold voltages wander. At worst, the parasitic bipolar
structures present in every CMOS process latch up and short the supply to ground until you
remove power. The `ptap` and `ntap` strips in the picture prevent that. They are the most
commonly forgotten thing in a first layout, and the default design-rule check does not mention
them; see [The full DRC rule set](../guide/the-rule-set-you-are-not-running.md).
