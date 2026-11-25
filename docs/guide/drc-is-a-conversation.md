# Reading DRC errors

> **Ninety per cent of layout is messing stuff up.**
> — the team lead, and the reason this course is shaped the way it is

A design rule check (DRC) reports each problem in your layout as one sentence, and each sentence
says something specific about what the foundry's equipment can and can't make. Every rule exists
for a physical reason and every violation names the rule it broke, so the rule name tells you
what to fix.

The skill this course teaches is a loop: **read the rule name, understand the constraint, change
one thing, and run the check again.** In Lab 02 one pass of that loop takes about four seconds,
and you'll spend a lot of your layout time going round it.

## What a violation looks like

Magic checks the shapes you change as you draw. It covers each violation with white hatching and
keeps a count on the `DRC` button at the top of the window, and to find out what a particular
violation is, you put the box on it and choose `Drc → DRC report`:

![Lab 02's `drc_03` after `Drc → DRC update`, the `=` key and `Drc → DRC report`](../assets/img/ad104-g-drc-report.png){fig-alt="Magic's layout window, zoomed in on a poly contact with white hatching around it, and the console under it. The DRC button at the top reads DRC=14 on a red background. The console's last lines are No errors found, Error area #2, and the licon.8a message twice."}

*The `DRC` button says `DRC=14`, and the white hatching sits around the poly contact. `DRC update`
printed `No errors found.` because the box was still on empty space; `=` moved the box onto an
error, and `DRC report` named the rule broken inside it.*

```
No errors found.
Error area #2:
poly overlap of poly contact < 0.08um in one direction (licon.8a)
poly overlap of poly contact < 0.08um in one direction (licon.8a)
```

The box that `=` sets covers one small error tile, so the report names the one rule broken there.
With the box over the whole landing pad, `DRC report` names the rule twice: once as the plain
enclosure rule, `poly overlap of poly contact < 0.05um (licon.8)`, and once as the directional
version above.

That's cell `drc_03` from [Lab 02](../labs/lab-02-break-it-on-purpose-overview.md). Its poly
landing pad has been shrunk to 0.25 × 0.25 µm around a 0.17 µm cut, which leaves 0.04 µm of poly
on each side, and the rule asks for 0.05.

## Reading DRC in Magic

Everything you need is on the `Drc` menu, the `DRC` button and one key:

| Where | What it does |
|---|---|
| the `DRC` button | Shows the count, as `DRC=14`, once the cell has been checked. A cell you have just opened shows a green `DRC` and no count, even if it has errors, because Magic checks only what you change. |
| `Drc → DRC update` | Checks the whole cell and sets the count on the button. It then reports the rules broken inside the box, so if the box is on empty space the console says `No errors found.` while the button shows a count. |
| the `=` key | Puts the box on the next error and zooms out far enough that you can see where it is. The pointer has to be over the drawing. (`Drc → DRC Find next error` does the same but zooms in to a view about 0.1 µm wide, too close to see where you are.) |
| `Drc → DRC report` | Prints, in the console, the rule broken by every error inside the box. |
| `Options → DRC Manager` | Lists every rule the cell breaks, one row per rule, with the cell's errors under each. Select an error and press `Zoom` to go to it. Using the manager selects the whole cell, which writes the cell's name across the drawing; press `,` over the drawing to clear it. |
| `Drc → DRC Fast`, `Drc → DRC Complete` | Switch between the default and the full rule set. The count changes only at the next `DRC update`. See [The full DRC rule set](the-rule-set-you-are-not-running.md). |

`DRC report` is the one you'll use most, because the count only tells you how many violations
there are, while the report tells you what they are. The
[Magic cheat sheet](../reference/magic-cheatsheet.md) has the console form of each of these,
which the lab scripts use.

## "In one direction"

You'll see this phrasing often:

```
Local interconnect overlap of poly contact < 0.08um in one direction (li.5)
Metal1 overlap of local interconnect contact < 0.06um in one direction (met1.5)
N-diffusion overlap of N-diffusion contact < 0.06um in one direction (licon.5c)
```

It's easy to misread this as "0.08 µm somewhere". What the phrase actually means is: **pick
an axis, x or y, and on that axis the surrounding layer must extend past the contact by at least
that much on _both_ sides.**

So a contact centred in a shape that's generous vertically but tight horizontally passes, because
the y axis satisfies the rule on its own. A contact tucked into a corner fails, because neither
axis has clearance on both sides.

That's why the li (local interconnect) strips in Lab 03's reference inverter are 0.37 µm wide around a 0.17 µm contact. The
extra width gives 0.10 µm of overhang on the left and on the right, so the x axis satisfies the
rule by itself.

It's also why the fix for one of these violations is rarely to make everything bigger. Usually
you only need to make the shape bigger *on one axis*, and that often costs no area at all.

## The four kinds of rule

Almost every SKY130 rule you'll meet is one of four kinds:

| Kind | Reads like | Physically |
|---|---|---|
| **width** | `Local interconnect width < 0.17um (li.1)` | the printer can't resolve a line thinner than this |
| **spacing** | `Metal1 spacing < 0.14um (met1.2)` | two features closer than this merge, or short together |
| **enclosure / overlap** | `N-well overlap of P-Diffusion < 0.18um (diff/tap.8)` | the two masks don't align perfectly, so you leave a margin |
| **area** | `Local interconnect minimum area < 0.0561um^2 (li.6)` | a shape smaller than this lifts off or doesn't fill |

Once you can sort a message into one of those four kinds, you know which kind of edit fixes it:
make the shape wider, move it away, make the shape *around* it bigger, or make it bigger overall.

## Iterating to a clean layout

The reference inverter in Lab 03 wasn't drawn correctly the first time. Its first version had 62
violations across seven distinct rules: contacts too close to the edges of their diffusion, li
exactly the size of the contacts under it, a poly gate stripe narrower than the contact meant to
land on it, and taps with no overhang. The second version had zero.

It took two iterations, and that wasn't because the first attempt was careless. Nobody can hold
thirty enclosure rules in their head, and we don't expect you to. You draw what's obviously
right, the checker names the places where you were wrong, and each rule name tells you which
number to change.

That's why Lab 02 comes before Lab 03: you meet five real violations on somebody else's layout,
where being wrong costs you nothing, before you meet them on your own.

## Fixing by rule

The worst habit in layout is nudging shapes a little at a time until the white hatching goes
away. It does work eventually, but it takes ten times as long and teaches you nothing, and the
layout it produces is usually right only by accident, so a single edit can make it wrong again.

Instead, take the rule name and number from `DRC report`, look the number up, change the geometry
so that it satisfies the rule with a comfortable margin, and run the check again.

The [DRC error decoder](../reference/drc-error-decoder.md) lists every rule this course can make you
hit, with its number and the fix.
