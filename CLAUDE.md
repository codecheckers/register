# CODECHECK Register

## Project overview

This is the register of CODECHECK certificates, a dataset tracking reproducibility checks of scientific papers. The main data file is `register.csv`. Everything in `docs/` is generated — never edit it by hand.

## Related projects

The `codecheck` R package is at `../codecheck/` (sibling directory). It provides the rendering pipeline (`codecheck::register_render()`, `codecheck::register_check()`, `codecheck::register_clear_cache()`).

## Workflow

1. Edit `register.csv` to add or update certificates
2. Render with `R -q -e "codecheck::register_render(); warnings()"`
3. Commit both `register.csv` and the generated `docs/` output
4. Preview locally with `make serve` (nginx on port 80), stop with `make serve-stop`

## Conventions

- Commit messages: terse, lowercase, reference GitHub issues with `closes #N`
- Certificate IDs: `YYYY-NNN` format (e.g., `2026-001`)
- Branch: `master` (not `main`). Remotes: `upstream` and `nuest`
- `docs/` contains generated HTML, JSON, markdown — per-certificate pages, codechecker pages, venue pages, sitemap, robots.txt
- Register JSON API: `docs/register.json` (full), `docs/featured.json` (last 10)
