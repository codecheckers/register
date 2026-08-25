# CODECHECK Register

## Project overview

This is the register of CODECHECK certificates, a dataset tracking reproducibility checks of scientific papers. The main data file is `register.csv`. Everything in `docs/` is generated — never edit it by hand.

## Committing

**Never commit. Stage changes with `git add` and propose a commit message; the user commits.** This holds even in auto-accept mode and even when the change is trivial or the message was agreed beforehand. The same applies to pushing and to anything that publishes (Zenodo writes, GitHub issue comments): stage or draft it, then wait.

## Related projects

The `codecheck` R package is at `../codecheck/` (sibling directory). It provides the rendering pipeline (`codecheck::register_render()`, `codecheck::register_check()`, `codecheck::register_clear_cache()`) and all Zenodo logic (`../codecheck/R/zenodo.R`). Changes there need `tinytest::build_install_test(".")` (never `test_all`), a `NEWS.md` entry, and `devtools::document()`; then `make install_local` here to pick them up.

## Workflow

1. Edit `register.csv` to add or update certificates
2. Render with `R -q -e "codecheck::register_render(); warnings()"`
3. Stage both `register.csv` and the generated `docs/` output (see Committing)
4. Preview locally with `make serve` (nginx on port 80), stop with `make serve-stop`

## Adding a new certificate

1. Read the Zenodo record: `curl -s https://zenodo.org/api/records/<RECORD ID> | python3 -m json.tool`. Add `-H "Accept: application/vnd.inveniordm.v1+json"` for the representation the curation policy is written against (creators as `person_or_org`, alternate identifiers under `metadata.identifiers`).
2. Read `codecheck.yml` from the checked repository (`https://raw.githubusercontent.com/codecheckers/<repo>/<branch>/codecheck.yml`) for the certificate ID, paper reference, codechecker and `check_time`. This file, not the Zenodo record, is what the register renders from.
3. Find the register issue for the certificate. **`gh issue view` currently fails** with a Projects-classic GraphQL deprecation error; use the REST API instead:
   `gh api repos/codecheckers/register/issues/<N> --jq '.title+"\n"+.body'` and `gh api repos/codecheckers/register/issues/<N>/comments`.
   To find the issue by certificate ID: `gh api repos/codecheckers/register/issues --paginate --jq '.[] | "\(.number) \(.title)"'` — issue titles follow `Author names | YYYY-NNN`.
4. Append one row to `register.csv` (append at the end, the renderer sorts).
5. `make render`, then verify `docs/certs/<CERT ID>/index.html` exists and the entry in `docs/register.json` carries the right title, paper reference and check date.
6. Preview with `make serve` → `http://localhost/certs/<CERT ID>/`, then `make serve-stop`.
7. Stage `register.csv` and `docs/` together and propose the commit message (see Conventions).
8. Audit the Zenodo record: `make zenodo_check CERT_ID=<CERT ID>` (see below).
9. Propose the issue-closing comments (see below).

## Venue and type conventions

`register.csv` columns: `Certificate,Repository,Type,Venue,Issue`. `Venue` must be a `name` from `venues.csv`; a new venue needs a `venues.csv` row (`name,longname,label`) first.

- `community` + `codecheck` — community check published in the register itself
- `community` + `preprint` — community check where the checked work is a preprint
- `community` + `codecheck NL` — CODECHECK NL checks
- `journal` + the journal short name (`JOSIS`, `GigaScience`, `Lifecycle Journal`, …)
- `conference` + `AGILEGIS`
- `institution` + `TU Delft DCC`, `AUMC`, …

The GitHub issue labels (`community`, `journal`, `institution`, `conference`) mirror the `Type` column and are a good cross-check.

## Zenodo community curation

Certificates are archived in the [CODECHECK community on Zenodo](https://zenodo.org/communities/codecheck/), whose [curation policy](https://zenodo.org/communities/codecheck/curation-policy) the record metadata must follow: title `CODECHECK Certificate <ID>`, publisher `CODECHECK Community on Zenodo`, resource type `publication-report`, CC-BY, language set, the certificate PDF as preview plus a machine-readable source (`codecheck.Rmd`), a `Reviews` relation to the paper DOI, a relation to a repository under `codecheckers/` or `cdchck`, and both alternate identifiers `http://cdchck.science/register/certs/<ID>` (scheme `url`) and `cdchck.science/register/certs/<ID>` (scheme `other`).

- `make zenodo_check CERT_ID=2026-023` — read-only audit, no token needed
- `make zenodo_curate CERT_ID=2026-023` — show the proposed corrections (dry run)
- `make zenodo_curate CERT_ID=2026-023 APPLY=1` — write them; needs `ZENODO_TOKEN` in `.env`, and **always ask the user first**, this publishes a metadata update of a public record

Implemented in `../codecheck/R/zenodo.R` (`check_zenodo_record()`, `curate_zenodo_record()`, `zenodo_policy_check()`).

## Closing a register issue

The issue is closed by the commit message (`closes #N`). The closing conversation on the issue follows this pattern (see #195, #196, #202) — post as two comments:

```
<if the record was curated> Adjustments per https://zenodo.org/communities/codecheck/curation-policy: <what was changed>.

<Family>, <Initials>. (<year>). CODECHECK Certificate <CERT ID>. CODECHECK Community on Zenodo. https://doi.org/10.5281/zenodo.<RECORD ID>
```

```
Here is the certificate landing page in the register: https://codecheck.org.uk/register/certs/<CERT ID>/
```

Labels stay as they are. Draft the comments and let the user post them.

## Conventions

- Commit messages: terse, lowercase, reference GitHub issues with `closes #N`; for a new certificate: `add YYYY-NNN, closes #N`. Several at once: `add certificates YYYY-NNN and YYYY-MMM, rel #N, rel #M`
- Certificate IDs: `YYYY-NNN` format (e.g., `2026-001`)
- Branch: `master` (not `main`). Remotes: `upstream` and `nuest`
- `docs/` contains generated HTML, JSON, markdown — per-certificate pages, codechecker pages, venue pages, sitemap, robots.txt
- Register JSON API: `docs/register.json` (full), `docs/featured.json` (last 10)
- API keys live in the git-ignored `.env` (see `.env.example`); `make env` shows which are set without printing them
