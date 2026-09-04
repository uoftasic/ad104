# AD104 — Layout

Draw a transistor as geometry in Magic: DRC-clean, LVS-clean, and placed and
routed by hand.

**Published at <https://uoftasic.com/ad104/>.** Part of the
[UofT ASIC Team](https://uoftasic.com) education materials.

| | |
|---|---|
| **Track** | Analog |
| **Prerequisites** | IC101 → AD101 → AD102 → AD103 |
| **Workbench** | `hpretl/iic-osic-tools:2026.08` — Magic 8.3.681, netgen 1.5.323, KLayout 0.30.11, ngspice 47 |
| **Time** | 16–20 hours, self-paced |

## Quick start

```bash
. /foss/designs/common/.designinit
mod add ad104 && mod ad104
cd labs/lab-01-open-the-cell && make      # ~1.5 s, ends in PASS
```

Every lab pins `PDK=sky130A` itself and ships its own `.magicrc`, so `make`
works in a bare container with no environment setup, and every lab ends in
`PASS` or `FAIL` with a reason.

## Labs

| | | Runs in |
|---|---|---|
| [Lab 01](labs/lab-01-open-the-cell/) | Open a cell you did not draw — DRC, extract and LVS the foundry's own inverter | 1.5 s |
| [Lab 02](labs/lab-02-break-it-on-purpose/) | Five broken layouts, five real SKY130 rules, one of them invisible | 4 s |
| [Lab 03](labs/lab-03-draw-an-inverter/) | Draw a DRC-clean, LVS-clean CMOS inverter from an empty frame | 1.1 s |
| [Lab 04](labs/lab-04-buffer-and-and/) | A buffer and an AND gate, out of cells you already have | 1 min |
| [Lab 05](labs/lab-05-what-it-costs/) | Your cell against the foundry's, with parasitics | 2 min |
| [Capstone](labs/capstone-place-and-route/) | Place and route four standard cells, then find $f_{\max}$ | 1 min |

## Repository layout

| Path | |
|---|---|
| `docs/` | the published site (Docsify, no build step) |
| `labs/<id>/mag/` | `.mag` layouts — the files you edit |
| `labs/<id>/tcl/` | the Magic scripts `make` runs, written to be readable |
| `labs/<id>/spice/` | schematic netlists for LVS, and testbenches |
| `labs/<id>/src/` | Python checkers and deck generators |
| `labs/<id>/solutions/` | reference layouts, and a README arguing about the decisions in them |
| `labs/<id>/results/` | generated, gitignored |

## Preview the site locally

```bash
npx docsify-cli serve docs     # http://localhost:3000
```

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) and [`AGENTS.md`](AGENTS.md).
Questions: the [team Discord](https://discord.gg/hrJnP5UsGz).

## Licence

[MIT](LICENSE).
