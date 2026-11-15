# The answer key

These are the five cells, each the same inverter with its one mistake undone. Don't open them
until you have tried the cell yourself. What this lab teaches is how to read a rule name and work
out what the rule protects, and a diff of the fix tells you what to type without teaching you any
of that.

If you are stuck on one cell, do this before you look:

1. Run `make why C=3`, with your cell's number in place of 3. The rule name it prints is the
   answer, so read it as a sentence.
2. Look up that rule in
   [the DRC decoder](https://uoftasic.com/ad104/reference/drc-error-decoder.html).
3. In Magic, run `drc check`, put the cursor box over a white hatched area and type `drc why`.
   Magic names the same rule at that spot.

When you do look, look at only the one cell you are stuck on, make the fix yourself, and then go
back to the others.

`make solutions` regenerates these files from `tcl/make_fixed.tcl`, which is the same generator
as the broken cells with the five numbers put back.

## drc_05

`drc_05` is the only cell in this lab that the default rule set calls clean. Two independent
tools noticed the problem anyway: the full rule set reports `nwell.4`, and netgen says the
netlists do not match, because the PMOS body comes out on a node called `w_0_600#` instead of
`VPWR`.

We think it teaches more than the other four put together, because a missing tap doesn't look
like a mistake at all: there is simply nothing there to see.
