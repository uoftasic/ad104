# What sets the clock frequency

Everyone knows a chip has a clock speed. Few people are told what sets it, and the answer is in
the layout you have been drawing. This page builds the answer from numbers you measure in Lab 05
and the capstone.

## The timing rule

Between two flip-flops there is some logic. In one clock period, three things have to happen in
sequence:

1. the first flip-flop has to produce its output after the clock edge: the **clock-to-Q** delay
2. that value has to get through the logic and the wires: **the path delay**
3. it has to be stable at the second flip-flop's input a little *before* the next clock edge:
   the **setup time**

$$T_{\text{clk}} \;\ge\; t_{\text{clk}\rightarrow Q} \;+\; t_{\text{logic}} \;+\; t_{\text{setup}}$$

$$f_{\max} = \frac{1}{T_{\text{clk}}}$$

That is the whole rule. The rest of static timing analysis is bookkeeping around those three
terms.

## One gate delay

The fastest thing this process can do is one inverter driving one inverter and nothing else. You
can measure that directly with a **ring oscillator**, an odd number of inverters in a loop. An odd
loop cannot settle: whatever value it holds, it contradicts itself one lap later, so it
oscillates, with a period of $2 N t_p$.

[Lab 05](labs/lab-05-what-it-costs-overview.md) builds two 31-stage rings out of extracted
layouts:

| | period | frequency | one stage |
|---|---|---|---|
| the foundry's `inv_1` | 2137.8 ps | 467.8 MHz | **34.48 ps** |
| your Lab 03 inverter | 2720.4 ps | 367.6 MHz | **43.88 ps** |

**34 picoseconds** is the floor: one gate, unloaded, in SKY130 at 1.8 V. Every other number on
this page is a multiple of it.

## A real path

The capstone block is a flip-flop, two AND gates and a buffer in a row 14.6 µm long. Extract it
with parasitics, apply a clock edge, and watch Y:

```
      CLK rise -> Y rise        601.05 ps    (measured on your extracted layout)
      D setup at the flop       103.32 ps    (sky130_fd_sc_hd__tt_025C_1v80.lib)
      shortest legal period     704.37 ps
      f_max                    1419.71 MHz
```

That is **1.42 GHz**, for four levels of logic and almost no wire.

The numbers come from two different places:

- **601 ps is simulated**, on your own geometry, with every parasitic capacitance Magic could
  find.
- **103 ps is looked up**, from `sky130_fd_sc_hd__tt_025C_1v80.lib`, the same Liberty file the
  digital track synthesises against in [DD103](https://uoftasic.com/dd103/). Setup time is a
  property of the flip-flop's internals, and you cannot get it from your own layout. This is
  where the analog and digital tracks read the same file.

Six hundred picoseconds is **17 inverter delays** for four gates. The gates themselves are not
the problem. Most of it is the flip-flop's clock-to-Q, and the two `and2_0` cells you are given
are the weakest AND in the library.

## Why a real chip runs at 200 MHz

The arithmetic explains it, one term at a time.

**Logic depth.** Four levels is a toy. A real critical path, such as a 32-bit adder carry chain,
a cache tag comparison, or a decoder feeding a mux tree, is routinely twenty to forty levels. At
the same cost per level that is 2–5 ns before anything else.

**Wires.** Your capstone's longest net is about 2 µm. A net crossing a modest block is hundreds
of microns long, and a bus crossing a die is millimetres. Wire delay grows roughly with the
*square* of length, because both resistance and capacitance grow with it. Past a few hundred
microns the wire is the whole delay and the gates are a rounding error.

[DD103's ripple-adder page](https://uoftasic.com/dd103/) measures the same effect in the digital
track: a 4-bit ripple carry takes 1.481 ns and a 64-bit one takes 24.996 ns. The delay is in the
*chain*, not the gates.

**Clock skew and jitter.** The clock edge does not arrive everywhere at once, and every
picosecond of disagreement comes straight off the budget.

**Margin.** Everything above is the typical corner at 25 °C. Sign-off is done at the slow-slow
corner, 125 °C and low supply, where everything is 30–50 % worse, and the chip still has to work.

Stack those on the 1.42 GHz you measured and a few hundred megahertz is what is left. Nobody was
careless; the arithmetic gives that answer.

## The trade-offs

You can attack every one of those terms, and every attack costs something you also care about:

| You want | You do | You pay |
|---|---|---|
| less path delay | use stronger cells (`and2_2` not `and2_0`) | area, and input capacitance upstream |
| less path delay | fewer levels of logic | more gates in parallel, more area |
| less wire delay | put connected things next to each other | that is placement, and it is a global problem |
| less self-load | pack the layout tighter | your afternoon; Lab 05 measures what it is worth |
| more headroom | pipeline it: cut the path with another flip-flop | latency, and a flip-flop's worth of area and power |

Lab 05 measures the fourth row directly: your loose inverter is 27 % slower than the foundry's
in a ring, with identical transistors.

None of these moves is free. A synthesis and place-and-route tool chooses among them a few million
times, guided by an objective function. This course was about knowing what it is choosing
between.
