# CODECHECK Register

## Project overview

This is the register of CODECHECK certificates, a dataset tracking reproducibility checks of scientific papers. The main data file is `register.csv`. Everything in `docs/` is generated — never edit it by hand.

## Committing

**Never commit. Stage changes with `git add` and propose a commit message; the user commits.** This holds even in auto-accept mode and even when the change is trivial or the message was agreed beforehand. The same applies to pushing and to anything that publishes (Zenodo writes, GitHub issue comments): stage or draft it, then wait.

## Related projects

The `codecheck` R package is at `../codecheck/` (sibling directory). It provides the rendering pipeline (`codecheck::register_render()`, `codecheck::register_check()`, `codecheck::register_clear_cache()`) and all Zenodo logic (`../codecheck/R/zenodo.R`). Changes there need `tinytest::build_install_test(".")` (never `test_all`), a `NEWS.md` entry, and `devtools::document()`; then `make install_local` here to pick them up.

While iterating, skip the full build: `R CMD INSTALL --no-docs --no-byte-compile --no-staged-install .` installs in about 5 seconds, and a single test file runs with `R -q -e 'library(codecheck); setwd("inst/tinytest"); tinytest::run_test_file("test_<name>.R")'`. Run the full `build_install_test(".")` once before proposing the change.

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

Certificates are archived in the [CODECHECK community on Zenodo](https://zenodo.org/communities/codecheck/), whose [curation policy](https://zenodo.org/communities/codecheck/curation-policy) the record metadata must follow: title `CODECHECK Certificate <ID>`, publisher `CODECHECK Community on Zenodo`, resource type `publication-report`, language set, the certificate PDF as preview plus a machine-readable source (`codecheck.Rmd`), a `Reviews` relation to the paper DOI, a relation to a repository under `codecheckers/` or `cdchck`, and both alternate identifiers `http://cdchck.science/register/certs/<ID>` (scheme `url`) and `cdchck.science/register/certs/<ID>` (scheme `other`).

- `make zenodo_check CERT_ID=2026-023` — read-only audit, no token needed
- `make zenodo_curate CERT_ID=2026-023` — show the proposed corrections (dry run)
- `make zenodo_curate CERT_ID=2026-023 APPLY=1` — write them; needs `ZENODO_TOKEN` in `.env`, and **always ask the user first**, this publishes a metadata update of a public record

**Licences**: the record must carry **CC-BY 4.0**, which covers the certificate PDF. It *may* carry further licences alongside it when the deposit also contains other artefacts — code, data, a source archive — under different terms. Never strip an existing licence when adding CC-BY: the other entries are the depositor's deliberate choice for those files. Curation adds CC-BY 4.0 to the rights list and leaves the rest untouched.

**New versions do not inherit later metadata edits.** When a record is re-versioned (e.g. to work around Zenodo's `Files are not enabled` error on older deposits), the new version starts from the *original* metadata, so previously applied curation is lost. Always re-run `make zenodo_check CERT_ID=…` on a record after a new version is published, and update the `report` DOI in the repository's `codecheck.yml` to the new version.

Implemented in `../codecheck/R/zenodo.R` (`check_zenodo_record()`, `curate_zenodo_record()`, `zenodo_policy_check()`).

## Metadata curation of published records

Records that the maintainer token cannot edit (Zenodo answers `Permission denied` because the deposit belongs to the codechecker's account) are handed back to the codechecker through the certificate's original register issue. The established process, see #205 and the twelve issues linked from it:

1. Find the issue via the `Issue` column of `register.csv`, and the codechecker's GitHub handle by matching their ORCID against `docs/codecheckers/<handle>/index.html` (the redirect pages map handle to ORCID).
2. Post a comment that opens by @-mentioning the codechecker, explains the audit briefly, and gives a **table of the concrete changes** (field, current value, target value) for their record.
3. Add the `metadata curation` label — with a JSON array, `gh api repos/codecheckers/register/issues/<N>/labels --input - <<< '{"labels":["metadata curation"]}'`. The `-f 'labels[]=…'` form returns HTTP 422.
4. Re-open the issue (`gh api repos/codecheckers/register/issues/<N> -X PATCH -f state=open`), so the request is not lost in a closed thread.
5. Show the drafts to the user before posting.

**Tone**: apologetic about reviving an old thread, appreciative of the original check, never demanding. These are volunteers being asked about years-old work. Always offer the alternative of granting edit access instead of doing it by hand: on the record page **Share** → **People** tab → **Add people** → search **User** for `nuest` or `daniel.nuest@tu-dresden.de` → **Access**: **Can edit** → **Add**. Close with an explicit "or say so here and we will" so no one is stuck.

Existing examples to copy from: [#5](https://github.com/codecheckers/register/issues/5#issuecomment-5422719426) (the standard case), [#8](https://github.com/codecheckers/register/issues/8#issuecomment-5422720238) (paper reference is not a DOI), [#44](https://github.com/codecheckers/register/issues/44#issuecomment-5422723259) (record not in the Zenodo community), [#66](https://github.com/codecheckers/register/issues/66#issuecomment-5422992328) (asking for information rather than an edit).

Adapt the template per record rather than sending it verbatim — drop claims that do not hold (e.g. "despite it being part of the community" for a record that is not in the community), and never ask for a change that does not apply.

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
