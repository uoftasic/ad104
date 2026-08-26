# Getting started

You need three things before Lab 01: the workbench, this repo inside it, and
Magic opening with the SKY130 technology loaded. That last one is the only
part that ever goes wrong, and it goes wrong in a way that does not say so.

## Prerequisites

[IC101](https://uoftasic.com/ic101/) → [AD101](https://uoftasic.com/ad101/) →
[AD102](https://uoftasic.com/ad102/) → [AD103](https://uoftasic.com/ad103/).

This course assumes AD103 in particular. You should have drawn a CMOS
inverter in XSchem, swept its transfer curve, and be comfortable with the idea
that $W$ and $L$ are numbers you choose. AD104 takes exactly that inverter and
asks where the silicon goes.

## The workbench

Everything runs in the noVNC desktop from IC101:
`hpretl/iic-osic-tools:2026.04`. Start it the way IC101 told you, open
`http://localhost` in a browser, and use the terminal on that desktop.

```bash
. /foss/designs/common/.designinit
echo $PDK
```

`$PDK` must print **`sky130A`**. The image ships with `PDK=ihp-sg13g2`, which
is a real 130 nm process from a different foundry with different layer names
and different rules. Magic will happily open in it and every layer this course
names will be missing.

```bash
mod add ad104     # first time only
mod ad104
magic --version   # expect: 8.3.636
```

## Magic, the first time

Magic is older than most of the people taking this course — it started at
Berkeley in 1983 — and it looks it. It is also the only open-source layout
editor with a live design-rule checker, a built-in extractor, and a scripting
console, which is why the whole SKY130 open ecosystem is built around it.

**Every lab in this course opens Magic for you.** From inside a lab package:

```bash
make edit
```

If you want to open a cell by hand, `cd` into a directory that has a
`.magicrc` in it and name the cell without its `.mag` extension:

```bash
cd labs/lab-03-draw-an-inverter/mag
magic -d X11 my_inv
```

Two windows appear: **`layout1`**, where the picture is, and **`tkcon`**, a
Tcl console. The console is not a debugging aid. It is the primary interface —
every command in this course can be typed there, and the labs drive Magic by
feeding it exactly those commands.

### `-d X11`, and why it is not optional

Magic has three graphics drivers in this image. `X11` is the one that works.
The Cairo/OpenGL driver (`-d XR`) can fail with a `BadAlloc` inside the
container, and when it does the window is black rather than absent, which
takes a while to diagnose. The team's `.designinit` encodes this as the
`magic130` alias for the same reason. Use `-d X11`.

### `.magicrc`, and why every lab ships one

Magic reads a file called `.magicrc` from **the directory you started it in**.
Every lab package in this course has one, and it is two lines:

```tcl
if {[info exists env(PDK_ROOT)]} {
    source $env(PDK_ROOT)/sky130A/libs.tech/magic/sky130A.magicrc
}
```

Without it Magic starts in its own default technology (`scmos`), which has
about a dozen layers, none of them SKY130's. The symptom is
`Failed to load technology`, or worse, a Magic that opens fine and simply has
no `nwell` in the layer list.

If you start Magic somewhere without a `.magicrc`, make one:

```bash
echo 'source $PDK_ROOT/sky130A/libs.tech/magic/sky130A.magicrc' > .magicrc
```

## What the labs give you

Every lab is a directory with a `Makefile`, and `make` alone does the whole
thing and prints a verdict:

| | |
|---|---|
| `make` | run every check and print `PASS` or `FAIL` with a reason |
| `make edit` | open the cell you are working on in Magic |
| `make clean` | delete `results/` |

The Makefiles pin `PDK=sky130A` themselves, so **the labs work even if
`.designinit` did not**. If something in this guide does not work, run `make`
in the lab anyway — it is the ground truth, and it tells you what it found in
words.

## Getting help

The [team Discord](https://discord.gg/hrJnP5UsGz) is the place. Layout is a
craft and it is genuinely faster to be shown than to read. A screenshot of
your Magic window with the DRC count in the toolbar is usually enough for
someone to spot it.

When a tool has an opinion, paste the opinion. `drc why` names a rule; netgen
names a net. Those names are searchable and specific, and "it doesn't work" is
not.

## Things that go wrong before you have drawn anything

| What you see | What it is |
|---|---|
| `Failed to load technology "sky130A"` | No `.magicrc` in the directory you started Magic from. Make one — two lines, above. |
| Magic opens, and there is no `nwell` in the layer list | Same cause. The technology did not load, so you are in `scmos`. |
| `Cell ... couldn't be read` | You named a cell that does not exist here, or you are in the wrong directory. Magic then creates an empty cell with that name, which is why an empty window is a common symptom. |
| The layout is one empty rectangle with a name in it | An unexpanded subcell. Select it and press `x`, or type `expand`. |
| `.designinit: No such file or directory` | The workspace was not set up. Run `make` in a lab anyway — every lab package pins its own PDK. |
| Everything looks dim and the title says `[NOT BEING EDITED]` | You are looking at a cell that is not the edit cell. `load <name>` makes it the edit cell. |
| `couldn't read Username for 'https://github.com'` on `mod add ad104` | The repo did not answer anonymously. That is on us, not you — say so in Discord. |
