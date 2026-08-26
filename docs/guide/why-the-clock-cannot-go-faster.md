# Why the clock cannot go faster

Everyone knows a chip has a clock speed. Almost nobody is told what sets it,
and the answer is entirely in the layout you have just been drawing.

## The rule

Between two flip-flops there is some logic. In one clock period, three things
have to happen in sequence:

1. the first flip-flop has to produce its output after the clock edge —
   **clock-to-Q**
2. that value has to get through the logic and the wires — **the path delay**
3. it has to be sitting still at the second flip-flop's input a little *before*
   the next clock edge — **setup time**

$$T_{\text{clk}} \;\ge\; t_{\text{clk}\rightarrow Q} \;+\; t_{\text{logic}} \;+\; t_{\text{setup}}$$

$$f_{\max} = \frac{1}{T_{\text{clk}}}$$

That is the whole of it. Everything else in static timing analysis is
bookkeeping around those three terms.

## Measuring the first term yourself

The fastest thing this process can do is one inverter driving one inverter and
nothing else. You can measure it directly with a **ring oscillator**: an odd
number of inverters in a loop. An odd loop cannot settle — whatever it
decides, it disagrees with itself one lap later — so it runs, and its period
is $2 N t_p$.

[Lab 05](labs/lab-05-what-it-costs-overview.md) builds two 31-stage rings
out of extracted layouts:

| | period | frequency | one stage |
|---|---|---|---|
| the foundry's `inv_1` | 2137.8 ps | 467.8 MHz | **34.48 ps** |
| your Lab 03 inverter | 2720.4 ps | 367.6 MHz | **43.88 ps** |

**34 picoseconds** is the floor. One gate, unloaded, in SKY130 at 1.8 V. Every
other number in this page is a multiple of that one.

## Measuring a real path

The capstone block is a flip-flop, two AND gates and a buffer in a row 14.6 µm
long. Extract it with parasitics, put a clock edge in, and watch Y:

```
      CLK rise -> Y rise        601.05 ps    (measured on your extracted layout)
      D setup at the flop       103.32 ps    (sky130_fd_sc_hd__tt_025C_1v80.lib)
      shortest legal period     704.37 ps
      f_max                    1419.71 MHz
```

**1.42 GHz**, for four levels of logic and no wires to speak of.

Two things about where those numbers come from:

- **601 ps is simulated**, on your own geometry, with every parasitic
  capacitance Magic could find.
- **103 ps is looked up**, from `sky130_fd_sc_hd__tt_025C_1v80.lib` — the same
  Liberty file the digital track synthesises against in
  [DD103](https://uoftasic.com/dd103/). Setup time is a property of the
  flip-flop's internals; you cannot get it from your own layout, and this is
  the point where the analog and digital tracks are looking at the same file.

Six hundred picoseconds is **17 inverter delays** for four gates. The gates
themselves are not the problem; the flip-flop's clock-to-Q is most of it, and
the two `and2_0` cells you were given are the weakest AND in the library.

## So why does a real chip run at 200 MHz?

Take the arithmetic seriously and it is not mysterious at all.

**Logic depth.** Four levels is a toy. A real critical path — a 32-bit adder
carry chain, a cache tag comparison, a decoder feeding a mux tree — is
routinely twenty to forty levels. At the same per-level cost that is 2–5 ns
before anything else.

**Wires.** Your capstone's longest net is about 2 µm. A net crossing a modest
block is hundreds of microns; a bus crossing a die is millimetres. Wire delay
grows roughly with the *square* of length, because both the resistance and the
capacitance grow with it, and past a few hundred microns the wire is the whole
delay and the gates are rounding error.

[DD103's ripple-adder page](https://uoftasic.com/dd103/) measures the same
effect in the digital track: a 4-bit ripple carry takes 1.481 ns and a 64-bit
one takes 24.996 ns — the delay is in the *chain*, not the gates.

**Clock skew and jitter.** The edge does not arrive everywhere at once, and
every picosecond of disagreement comes straight off the budget.

**Margin.** Everything above is the typical corner at 25 °C. Sign-off is done
at slow-slow, 125 °C, low supply, where everything is 30–50 % worse, and you
still have to work.

Stack those up on the 1.42 GHz you measured and a few hundred megahertz is
what is left. Not because anyone was careless — because the arithmetic says so.

## The trade you now know how to make

Every one of those terms is something you can attack, and every attack costs
something you also care about:

| You want | You do | You pay |
|---|---|---|
| less path delay | use stronger cells (`and2_2` not `and2_0`) | area, and input capacitance upstream |
| less path delay | fewer levels of logic | more gates in parallel, more area |
| less wire delay | put connected things next to each other | that is placement, and it is a global problem |
| less self-load | pack the layout tighter | your afternoon, and Lab 05 measures exactly how much it is worth |
| more headroom | pipeline it — cut the path with another flip-flop | latency, and a flip-flop's worth of area and power |

You have now measured the fifth row directly: your loose inverter is 27 % slower
than the foundry's in a ring, for identical transistors.

There is no free move on that list. Choosing among them, a few million times,
with an objective function, is what a synthesis and place-and-route tool is.
Knowing what it is choosing between is what this course was for.
