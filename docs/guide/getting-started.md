# Getting started

Before Lab 01 you need three things: the workbench, this course's files inside it, and Magic
opening with the SKY130 technology loaded. The third is the one that goes wrong, and when it does
the message you get does not say why. This page explains how the pieces fit together.
IC101 sets up the workbench, and
[Lab 01, Part 1](../labs/lab-01-open-the-cell-overview.md#part-1-load-the-course) loads this course
into it.

## Prerequisites

[IC101](https://uoftasic.com/ic101/) → [AD101](https://uoftasic.com/ad101/) →
[AD102](https://uoftasic.com/ad102/) → [AD103](https://uoftasic.com/ad103/).

AD103 matters most. You should have drawn a CMOS inverter in XSchem, swept its transfer curve,
and be comfortable with the idea that $W$ and $L$ are numbers you choose. AD104 takes that
inverter and asks where the silicon goes.

## The workbench

Everything runs in the noVNC desktop from IC101, which is the image
`hpretl/iic-osic-tools:2026.08`. You start it the way IC101 showed you, open `http://localhost`
in a browser, and type commands in the terminal on that desktop.

The image can work with more than one process, and the environment variable `$PDK` picks which.
This course needs **`sky130A`**. The image ships with `PDK=ihp-sg13g2`, a real 130 nm process from
a different foundry, with different layer names and different rules. Magic opens in it without
complaint, and every layer this course names is missing.

The course environment script, `/foss/designs/common/.designinit`, switches the whole shell to
SKY130. It also defines `mod`, the command that copies a course's files into your workspace. You
load the script once in every new terminal.

## Magic

Magic is older than most of the people taking this course: it started at Berkeley in 1983, and it
looks it. It is also the only open-source layout editor with a live design-rule checker, a
built-in extractor and a scripting console, which is why the open SKY130 ecosystem is built
around it.

Every lab opens Magic for you with `make edit`, run from inside the lab package. That starts
Magic in the folder holding the `.mag` file and names the cell without its `.mag` extension, for
example `magic -d X11 my_inv` in `labs/lab-03-draw-an-inverter/mag`.

Two windows appear: **`layout1`**, which shows the drawing, and **`tkcon`**, a Tcl console. The
console is the main way you work in this course. Every command in the guide pages and labs can be
typed there, and the lab scripts drive Magic by feeding it the same commands.

### The `-d X11` option

Magic has three graphics drivers in this image, and `X11` is the one that works. The Cairo/OpenGL
driver (`-d XR`) can fail with a `BadAlloc` inside the container, and when it does you get a black
window instead of no window, which takes a while to diagnose. The team's `.designinit` defines a
`magic130` alias that uses `-d X11` for the same reason.

### Where Magic gets the technology

Magic decides which technology to load when it starts, from two startup files:

- The image's own `~/.magicrc` loads whichever PDK `$PDK` names. With the image's default
  `PDK=ihp-sg13g2` you get IHP's layers and none of SKY130's.
- A file called `.magicrc` in **the directory you start Magic in**. Every lab package has one at
  its top level. It loads SKY130 if nothing has loaded it yet, and does nothing if
  `~/.magicrc` already did. That check matters: a `.magicrc` that loads SKY130 a second time
  makes Magic print `Error parsing ".magicrc": can't rename to "closewrapperonly": command
  already exists` and `Bad local startup file ".magicrc", continuing without.` in the first two
  lines of the console, which looks like a broken toolchain on one that is fine.

Every lab's Makefile also sets `PDK=sky130A` for the Magic it starts, so `make edit` opens in
SKY130 even if `.designinit` failed for you.

If no technology file gets loaded, Magic starts in its own default technology, `scmos`, which has
about a dozen layers, none of them SKY130's. The symptom is `Failed to load technology`, or a
Magic that opens normally and has no `nwell` in its layer list.

## What the labs give you

Every lab is a folder with a `Makefile`, and `make` on its own runs every check and prints a
verdict:

| | |
|---|---|
| `make` | run every check and print `PASS` or `FAIL` with a reason |
| `make edit` | open the cell you are working on in Magic |
| `make clean` | delete `results/` |

The Makefiles set `PDK=sky130A` themselves, so **the labs work even if `.designinit` did not**.
If a setup step in Lab 01 does not work for you, run `make` in the lab anyway. It checks
everything itself and says what it found in words.

## Getting help

Ask in the [team Discord](https://discord.gg/hrJnP5UsGz). Layout is a craft, and it is faster to
be shown than to read about it. A screenshot of your Magic window with the DRC count in the
toolbar is usually enough for someone to spot the problem.

When a tool reports a problem, paste its exact words. `drc why` names a rule and netgen names a
net. Those names are specific and searchable; "it doesn't work" is not.

## Problems opening Magic

Setup problems with `.designinit` and `mod` are covered at the step where they happen, in
[Lab 01, Part 1](../labs/lab-01-open-the-cell-overview.md#part-1-load-the-course).

| What you see | What it means |
|---|---|
| `Failed to load technology "sky130A"` | No SKY130 startup file was loaded. Open the cell with `make edit` from its lab folder, or copy a lab's `.magicrc` into the folder you start Magic in. |
| Magic opens, and there is no `nwell` in the layer list | Same cause. The technology did not load. |
| `Bad local startup file ".magicrc", continuing without.` | A `.magicrc` loaded SKY130 a second time. Use a copy of a lab's `.magicrc`, which checks first. |
| `Cell ... couldn't be read` | You named a cell that does not exist in this folder, or you are in the wrong folder. Magic then creates an empty cell with that name, which is why an empty window is a common symptom. |
| The layout is one empty rectangle with a name in it | An unexpanded subcell. Select it and press `x`, or type `expand`. |
| Everything looks dim and the title says `[NOT BEING EDITED]` | You are looking at a cell that is not the edit cell. `load <name>` makes it the edit cell. |
