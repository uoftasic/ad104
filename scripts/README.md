# Scripts

Repo-level utilities for **AD104 — Layout** (`uoftasic/ad104`).

Everything a student runs lives in `labs/<lab-id>/` and is driven by that
lab's `Makefile`. This directory is for repo maintenance only.

## Entry points

| Script | Purpose |
|--------|---------|
| `init-template.py` | Fill in course id / title / description after creating a repo from the template. Already run for this course. |
| `check_site.py` | After `quarto render docs`, check that every local link, image and `#anchor` in `docs/_site` resolves, and that every page has the navbar's link to https://edu.uoftasic.com/: `python3 scripts/check_site.py docs/_site`. CI runs it in `.github/workflows/site.yml`. |
| `figures/` | The scripts that draw the circuit figures in `docs/assets/img/` with schemdraw. `pip install -r scripts/figures/requirements.txt`, then `python3 scripts/figures/<name>.py` rewrites that figure's SVG |

## Conventions

- Prefer Python; layout tooling belongs in `labs/<id>/tcl/` and `labs/<id>/src/`.
- No secrets in the repo.
- Document new scripts here when you add them.
