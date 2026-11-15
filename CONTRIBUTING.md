# Contributing

Thanks for improving materials for the **UofT ASIC Team**.

## After creating a course from this template

1. Run `scripts/init-template.py` with `--id`, `--title`, and `--description` (org is always `uoftasic`).
2. Enable GitHub Pages with **Source: GitHub Actions**; `.github/workflows/site.yml` builds `docs/` with Quarto and deploys it.
3. Prefer repo names that match course ids (`dd103`, `ic101`, …).

See [TEMPLATE.md](TEMPLATE.md).

## Placeholders

Only these three are fillable:

| Token | Example |
|-------|---------|
| `ad104` | `dd103` |
| `AD104 — Layout` | `DD103 — RTL on FPGAs & ASICs` |
| `Draw a transistor as geometry in Magic: DRC-clean, LVS-clean, and placed and routed by hand.` | `RTL synthesis intro with Yosys` |

## Conventions

| Item | Convention |
|------|------------|
| Org | `uoftasic` |
| Default branch | `main` |
| Docs pages | kebab-case `.md` under `docs/` |
| Lab IDs | `lab-NN-short-name` |
| Adding a guide page | add `.md` under `docs/guide/` (reading only; activities go in a lab), add it to the Course path, the sidebar in `docs/_quarto.yml` and the chapters in `docs/_quarto-pdf.yml` |
| Adding a lab | `labs/<id>/` + `docs/labs/<id>-overview.md` + a Course path row in `docs/index.md` + a sidebar entry in `docs/_quarto.yml` and a chapter in `docs/_quarto-pdf.yml`, all in the same order |
| Links between pages | relative to the page they are written in (`../guide/x.md` from a lab) |
| Lab writeup | titled `# Lab NN: Title`; each part opens with the question it answers and ends in a "You should see" check; at least one required part has the student produce something; explanations go in collapsed `<details>` answers; optional parts last. Ends with You're done when (the student's own work), Questions, Submit, then Going further and the "Next on the Course path" line. Full shape in [AGENTS.md](AGENTS.md#lab-writeup-shape) |
| Course path row | `#`, Read or Do in plain text, the page links (a Do row's lab as "Lab NN: Title" plus one sentence on what you'll do), and a time. Row times add up to the course total. Format in [AGENTS.md](AGENTS.md#course-path-format) |
| Binaries | small images in `docs/assets/`; large data → Git LFS or external |

## Docs vs labs

- **`docs/`**: the published site. Guide pages (reading only) are in `docs/guide/`, and lab *writeups* (where students run things) are in `docs/labs/`.
- **`labs/`**: runnable HDL / Python / data. Each `labs/<id>/README.md` links to its writeup on the site.
- **`scripts/`**: utilities; list entry points in `scripts/README.md`.

Do not put grades, solution keys, or PII under `docs/`. Prefer `labs/**/solutions/` and gitignore them on student forks when needed.

## Local docs preview

```bash
quarto preview docs     # -> http://localhost:4200
```

## Pull requests

Keep changes focused. For doc-only PRs, check navigation and math in the local preview when you can. On a pull request that touches `docs/`, CI renders the site and checks its links and anchors with `scripts/check_site.py` (`.github/workflows/site.yml`), and runs lychee over `docs/**/*.md` (`.github/workflows/docs-link-check.yml`).
