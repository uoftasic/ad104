# AD104 — Layout

AD103 ended with a CMOS inverter you could simulate. It was two symbols and a
wire. **This course is where it becomes a shape.**

Part of the **UofT ASIC Team** education materials. Published at **https://uoftasic.com/ad104/**.
Labs run inside the shared **workspace** you set up in [IC101](https://uoftasic.com/ic101/).

## At a glance

| | |
|---|---|
| **Track** | Analog |
| **Prerequisites** | [IC101](https://uoftasic.com/ic101/) → [AD101](https://uoftasic.com/ad101/) → [AD102](https://uoftasic.com/ad102/) → [AD103](https://uoftasic.com/ad103/), in that order |
| **Main tool** | **Magic** 8.3.636 — the layout editor. You have not used it before; [Getting started](guide/getting-started.md) assumes that. |
| **Also** | netgen for LVS, KLayout 0.30.8 for looking at GDS, ngspice 46 for what the geometry costs you |
| **Math level** | Arithmetic and a ruler. Every dimension in this course is a number of microns. |
| **Time** | 16–20 hours, self-paced. More if you enjoy it, and you might. |

> **This course is pinned to the workbench image `hpretl/iic-osic-tools:2026.04`**,
> which ships **Magic 8.3.636**, **netgen 1.5.318** and **KLayout 0.30.8**.
> Check yours with `magic --version`.

> **If your environment setup fails, run `make` anyway.** Every lab pins
> `PDK=sky130A` itself and ships its own `.magicrc`, so the labs run to
> completion in a bare container with no setup at all, and each one ends in
> `PASS` or `FAIL` with a reason.

## What this course is about

A schematic says *what is connected to what*. A layout says *what is where*.
Everything a chip actually costs — area, speed, power, yield — is decided in
the second document, not the first.

You will draw a transistor as coloured rectangles, find out from the tools
that it cannot be manufactured, fix it, prove it is still the circuit you
meant, and then measure what your particular arrangement of rectangles cost
compared with the foundry's.

**Ninety per cent of layout is messing things up.** That is not a warning, it
is the syllabus. This course puts real broken layouts in front of you on
purpose, in the first hour, before you have anything of your own to lose.

![The inverter you are going to draw](assets/img/ad104-magic-my-inv.png)

*Your inverter at the end of Lab 03: nwell hatched at the top, PMOS in orange
p-diffusion, NMOS in green n-diffusion, one red poly stripe crossing both —
that stripe is the gate, and its width is L — contacts as the boxed X's, local
interconnect in pale blue, and the two purple metal1 supply rails.*

## What you'll do

1. Open a cell **you did not draw** — the foundry's own inverter — and make
   four tools agree about it, before drawing anything
2. Fix **five broken layouts**, each breaking exactly one real SKY130 rule,
   including one the default rule set calls clean
3. Draw a **DRC-clean, LVS-clean CMOS inverter** from an empty frame
4. Turn it into a **buffer** and an **AND gate** without drawing a single new
   transistor
5. Compare your cell against the foundry's **with parasitics extracted**, and
   find out that identical transistors drawn differently are 4.8× the area and
   27 % slower
6. **Place and route four standard cells by hand**, get the row clean, and
   then measure the highest clock frequency your own layout can survive

## Path

| Part | Guide | Lab |
|------|-------|-----|
| 0 | [Getting started](guide/getting-started.md) | [Lab 01 — Open a cell you did not draw](labs/lab-01-open-the-cell-overview.md) |
| I — Just start drawing | [What a layout actually is](guide/what-a-layout-actually-is.md) · [Stick diagrams](guide/stick-diagrams.md) · [Play with SiliWiz first](guide/siliwiz.md) | — |
| II — Read before you draw | [Anatomy of a standard cell](guide/anatomy-of-a-standard-cell.md) · [Drawing in Magic](guide/drawing-in-magic.md) | [Lab 03 — Draw an inverter](labs/lab-03-draw-an-inverter-overview.md) |
| III — DRC | [DRC is a conversation](guide/drc-is-a-conversation.md) · [The rule set you are not running](guide/the-rule-set-you-are-not-running.md) | [Lab 02 — Break it on purpose](labs/lab-02-break-it-on-purpose-overview.md) |
| IV — LVS | [Extraction is reverse engineering](guide/extraction-is-reverse-engineering.md) · [LVS asks a different question](guide/lvs-asks-a-different-question.md) | — |
| V — What it costs | [What your drawing costs](guide/what-your-drawing-costs.md) | [Lab 05 — What it costs](labs/lab-05-what-it-costs-overview.md) |
| VI — Assembly | [Cells are Lego](guide/cells-are-lego.md) · [Routing by hand](guide/routing-by-hand.md) | [Lab 04 — A buffer and an AND gate](labs/lab-04-buffer-and-and-overview.md) |
| VII — Time | [Why the clock cannot go faster](guide/why-the-clock-cannot-go-faster.md) | [Capstone — Place and route](labs/capstone-place-and-route-overview.md) |

Reference: [Magic cheat sheet](reference/magic-cheatsheet.md) ·
[The DRC error decoder](reference/drc-error-decoder.md) ·
[The SKY130 layer map](reference/sky130-layer-map.md)

**Stuck?** Ask in the [team Discord](https://discord.gg/hrJnP5UsGz). Nobody
expects you to work this out alone at 2 a.m. — see
[Getting help](guide/getting-started.md#getting-help).

## Quick start

```bash
# in the noVNC desktop, after IC101
. /foss/designs/common/.designinit
echo $PDK                      # must say sky130A, not ihp-sg13g2
mod add ad104                  # first time only
mod ad104
magic --version                # expect: 8.3.636
cd labs/lab-01-open-the-cell && make
```

That last command takes about a second and a half and should end in `PASS`.
It loads the foundry's own inverter, runs two different DRC rule sets over it,
pulls two transistors out of the geometry, and gets netgen to agree they are
the circuit the foundry says the cell is. If that works, your toolchain is
correct and every problem after this one is a drawing problem.

## What you'll have at the end

A standard cell you drew, a GDSII of a small block you placed and routed by
hand, a number for how fast it can be clocked, and the habit that makes layout
survivable: **run the checker, read the rule name, change one thing, run it
again.**

## Next courses

- **AD201** — Analog Signal Processing · **AD202** — Mixed Signal
- **DD103** — [RTL on FPGAs & ASICs](https://uoftasic.com/dd103/), where a tool
  does the place and route you just did by hand, in 54 seconds, for a whole chip
