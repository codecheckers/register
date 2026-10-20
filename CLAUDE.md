# CODECHECK Register

## Project overview

This is the register of CODECHECK certificates, a dataset tracking reproducibility checks of scientific papers. The main data file is `register.csv`. Everything in `docs/` is generated — never edit it by hand.

## Committing

**Never commit. Stage changes with `git add` and propose a commit message; the user commits.** This holds even in auto-accept mode and even when the change is trivial or the message was agreed beforehand. The same applies to pushing and to anything that publishes (Zenodo writes, GitHub issue comments): stage or draft it, then wait.

## Related projects

The `codecheck` R package is at `../codecheck/` (sibling directory). It provides the rendering pipeline (`codecheck::register_render()`, `codecheck::register_check()`, `codecheck::register_clear_cache()`) and all Zenodo logic (`../codecheck/R/zenodo.R`). Changes there need `tinytest::build_install_test(".")` (never `test_all`), a `NEWS.md` entry, and `devtools::document()`; then `make install_local` here to pick them up.

While iterating, skip the full build: `R CMD INSTALL --no-docs --no-byte-compile --no-staged-install .` installs in about 5 seconds, and a single test file runs with `R -q -e 'library(codecheck); setwd("inst/tinytest"); tinytest::run_test_file("test_<name>.R")'`. Run the full `build_install_test(".")` once before proposing the change.

## Workflow

For regular CODECHECK editing, **CI renders the register**: `.github/workflows/render.yml` runs `register_render()` on every push to `master` that touches `register.csv`, `venues.csv` or `persons.csv`, and commits the result as "Update register renderings".

1. Edit `register.csv` to add or update certificates
2. Validate the rows with `R -q -e 'codecheck::validate_register_rules()'` (seconds, no render)
3. Stage `register.csv` only (see Committing); the user pushes, and CI renders `docs/`
4. After the CI commit, check the result on the live site, e.g. `https://codecheck.org.uk/register/certs/<CERT ID>/`

**A local render is the exception**, for when CI cannot do the job: debugging a render, trying out a change to the `codecheck` package before it is in the image, or previewing something risky before pushing. Then render (see "Running a render from Claude Code"), preview with `make serve` (nginx on port 80, stop with `make serve-stop`), and stage only the `docs/` files the change touched.

A routine render never removes a certificate's OpenAlex ID or abstract just
because this run's CrossRef/OpenAlex lookup came back empty: a lookup that
merely failed (network error, rate limit) always keeps the previously
rendered value, and even a conclusive "not available" keeps it by default,
since that's more often a query problem than a real removal upstream. Only
`make render PRUNE_STALE=1` actually removes a confirmed-unavailable value —
use it deliberately, for a verified cleanup, not as part of a normal render.

## Visual and responsive testing

`docs/` is a static site, so the rendered pages can be checked in headless
Chrome without a server or any npm tooling:

```bash
make screenshots                        # home page at 393x851, 768x1024, 1280x900
make screenshots PATHS="/ /certs/2026-023/ /persons/"
make overflow                           # every page that scrolls sideways at 393px
make overflow WIDTH=768
```

- `test/screenshot.sh` serves `docs/` on a free port with `python3 -m
  http.server` and shoots each path at each viewport with
  `google-chrome --headless --screenshot`. It never renders - run `make render`
  first if `docs/` is stale.
- `393x851` is the CSS-pixel viewport of current Android phones (a Fairphone
  FP4 is 1080x2340 at DPR 2.75); use it for the mobile check.
- Chrome captures the **viewport**, not the full page, so pass a tall viewport
  (`-w 393x2000`) to see a footer or the lower half of a certificate page.
- `test/overflow.py` measures `documentElement.scrollWidth` against the
  viewport on each page and exits non-zero if any page is wider. A page that
  overflows drags the navigation and footer out with it and cuts off content
  with no visible way to reach it - the failure mode wide register tables had
  on phones. Anything that cannot fit must scroll inside its own container.
  (Chrome's `--dump-dom` ignores `--window-size`, so the script compares the
  numbers the page reports rather than the requested width.)

The page CSS is **not** in this repository: it is
`inst/extdata/templates/assets/codecheck-register.css` in `../codecheck/`,
copied into `docs/assets/` by every render. To iterate, edit it there, copy it
over (`cp ../codecheck/inst/extdata/templates/assets/codecheck-register.css
docs/assets/`) and re-run the checks - no re-render needed for a CSS-only
change. Layout rules for the register live in that one file; the rendered
pages are Bootstrap 3.3.5 via `rmarkdown::html_document`, while the plain
templates (404, redirect pages) load only this stylesheet.

## Profiling a render

`register_render(verbose = TRUE)` prefixes every log line with the seconds
elapsed since the render started, so a redirected log says where the time
went:

```bash
R -q -e 'codecheck::register_render(parallel = TRUE, verbose = TRUE)' > render.log 2>&1
grep -E "^\[ *[0-9.]+s\] (──|✔ Completed|✔ Main register)" render.log
```

A warm-cache full render is about **60 s**: ~10 s of (cached) metadata
lookups and PDF-link resolution, ~7 s for the 132 certificate pages, ~36 s
for the filter pages (persons is the largest at ~19 s), and a few seconds of
sitemap, redirects and policy audits. Certificates and filter pages both
render in parallel when `parallel = TRUE`.

A render that suddenly takes **six minutes** has lost its cache: everything
is re-fetched from OpenAlex, ORCID, ROR, Zenodo and GitHub. `make clean` does
that deliberately. When only a few certificates changed at their source - a
corrected `codecheck.yml`, a new report version - refresh just those with
`make clean_cert CERT_ID="2025-009 2025-010"`: it fetches their `codecheck.yml`
again and drops their abstract, OpenAlex ID, PDF link and policy records, and
keeps the rest of the cache. It needs a `codecheck` version with
`register_clear_cache(certificates = )` (`make install_local`).

## Running a render from Claude Code

Only for the exceptions listed under "Workflow" - routine certificate additions are rendered by CI.
`make render` (which also runs the Zenodo and ResearchEquals policy audits)
took about **seven minutes** for the 2026-025 render, far beyond the ~2 minutes
a background shell task survives. Detach it, then wait on the R process
itself (Bash `run_in_background`):

```bash
setsid nohup make render > <scratchpad>/render.log 2>&1 < /dev/null &
while pgrep -f '^/usr/lib/R/bin/exec/R .*register_render' >/dev/null; do sleep 10; done; tail -5 <scratchpad>/render.log
```

The same works for `tinytest::build_install_test` in `../codecheck/` (pattern
`build_install_test`). Keep the pattern anchored at `^/usr/lib/R/bin/exec/R`:
an unanchored `pgrep -f register_render` also matches the waiting loop's own
command line, so it never sees the render end. Waiting on `$!` doesn't work
either: after `setsid nohup R …` that PID belonged to a wrapper that exited
right away while R kept running. A finished render ends its log with `✔ Register rendering complete`. The
`! codechecker ORCID and GitHub username missing …` warnings and the long
`✖` lists under the Zenodo/ResearchEquals curation policy headings are
pre-existing. Read them for the new certificate only.

**Stage only what the change touched.** The local cache never expires, so a
local render reverts metadata that CI fetched more recently. The 2026-025
render, for example, swapped 2025-007's abstract back, moved 2024-025's
publication date (and its `"days"` entry in every `stats.json`/`statistics.json`
that lists it) and dropped University of Twente affiliations. List the
suspects with
`git diff -U0 docs/ | grep -E '^\+\+\+|<other cert IDs or values>'`. Leave
whole files that only carry such drift unstaged, along with `docs/.meta.json`
and the build-info footer in `docs/rules/*/index.html`. Aggregate files
(`statistics.json`, `register*.json`) that mix the new certificate with a
drifted line can be staged, because the next CI render corrects them.
A new certificate also legitimately changes `.zenodo.json` (codechecker added
as contributor) and `persons.csv` (Wikidata items of newly resolved ORCIDs).

## Adding a new certificate

1. Read the Zenodo record: `curl -s https://zenodo.org/api/records/<RECORD ID> | python3 -m json.tool`. Add `-H "Accept: application/vnd.inveniordm.v1+json"` for the representation the curation policy is written against (creators as `person_or_org`, alternate identifiers under `metadata.identifiers`).
2. Read `codecheck.yml` from the checked repository (`https://raw.githubusercontent.com/codecheckers/<repo>/<branch>/codecheck.yml`) for the certificate ID, paper reference, codechecker and `check_time`. This file, not the Zenodo record, is what the register renders from. If the issue doesn't name the `codecheckers/` repository, the newest repositories in the org usually include it: `gh api 'orgs/codecheckers/repos?sort=created&direction=desc&per_page=8' --jq '.[]|.name+" "+.default_branch'`.
3. Find the register issue for the certificate. **`gh issue view` currently fails** with a Projects-classic GraphQL deprecation error; use the REST API instead:
   `gh api repos/codecheckers/register/issues/<N> --jq '.title+"\n"+.body'` and `gh api repos/codecheckers/register/issues/<N>/comments`.
   To find the issue by certificate ID: `gh api 'repos/codecheckers/register/issues?state=all&per_page=100' --paginate --jq '.[] | "\(.number) \(.title)"'` — issue titles follow `Author names | YYYY-NNN`. Without `state=all` the API returns open issues only.
   The comment thread of a long check can be 100 KB (logs, Dockerfiles, screenshots); grep it for links instead of reading it whole.
4. Append one row to `register.csv` (append at the end, the renderer sorts), leaving the `Wikidata` column empty.
5. Validate with `R -q -e 'codecheck::validate_register_rules()'`.
6. Stage `register.csv` alone and propose the commit message (see Conventions). After the user pushes, CI renders the certificate (see "Workflow").
7. Once the CI commit "Update register renderings" is in, verify `https://codecheck.org.uk/register/certs/<CERT ID>/` and the entry in `https://codecheck.org.uk/register/register.json` carry the right title, paper reference and check date.
8. Audit the Zenodo record: `make zenodo_check CERT_ID=<CERT ID>` (see below).
9. Propose the issue-closing comments (see below).

Render locally instead (steps as under "Running a render from Claude Code", then `make serve` → `http://localhost/certs/<CERT ID>/`) only when CI cannot do it, see "Workflow".

## Venue and type conventions

`register.csv` columns: `Certificate,Repository,Type,Venue,Issue,Wikidata`. `Wikidata` is the certificate's Wikidata item (see #50); it stays empty in a new row. `Venue` must be a `name` from `venues.csv`; a new venue needs a `venues.csv` row (`name,longname,label`; `fediverse` and `hashtags` optional, see README) first.

- `community` + `codecheck` — community check published in the register itself
- `community` + `preprint` — community check where the checked work is a preprint
- `community` + `codecheck NL` — CODECHECK NL checks
- `journal` + the journal short name (`JOSIS`, `GigaScience`, `Lifecycle Journal`, …)
- `conference` + `AGILEGIS`
- `institution` + `TU Delft DCC`, `AUMC`, …

The GitHub issue labels mirror the row, and `CC-REG-008` checks that they do (#232):

- exactly one **type label** - `community`, `journal`, `institution` or `conference` - equal to `Type`;
- a **venue label** equal to the venue's `name` in `venues.csv` (`JOSIS`, `AUMC`, `TU Delft DCC`, …), or to its `label` there when that is not a type (`check-nl`, `lifecycle journal`, `preprint`);
- no venue label when the type label alone names the venue, which is when exactly one venue in `venues.csv` carries the type as its `label`: `community` names `codecheck`, `conference` names `AGILEGIS`. A second venue with that `label` makes the venue label necessary for both.

A new venue therefore needs a GitHub label named after it as well as its `venues.csv` row, unless it is the only one of its type. The labels are mirrored to `codecheckers/testing-dev-register`.

## Validation rules

`rules-1.0.yml` and `rules-2.0.yml` list every check CODECHECK tooling applies, one file per version of the configuration file specification; the identifier scheme (`CC-CFG-…`, `CC-MET-…`, `CC-REG-…`) and how severities follow from MUST/SHOULD/MAY are in `RULES.md`. These files are the source of truth: a severity is changed here, never in code. The `codecheck` package bundles copies (refresh with `codecheck::update_codecheck_rules(from = "../register")` in `../codecheck/`) and runs them with `validate_codecheck_yml_rules()` for a `codecheck.yml` and `validate_register_rules()` for `register.csv` - the latter also runs at the start of `register_check()`, so a new row with an unknown type, an unknown venue or an identifier that jumps more than 9 past the year's previous one is reported there.

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
Once approved, post each one from a JSON file:
`gh api repos/codecheckers/register/issues/<N>/comments -X POST --input <json>`
(a file with a `body` field).

## Opening Lifecycle Journal check issues

Issues follow `.github/ISSUE_TEMPLATE/new-lifecycle-journal-codecheck.md`
(labels `lifecycle journal`, `needs codechecker`, assignee `nuest`). Keep the
body to the template: submission DOI and links to code and data. No author
lists, ORCIDs or remarks such as a missing licence.

- **Find the right submission.** Each article has several DOIs
  (`10.71240/lcyc.*`), one per stage (`ResearchPlan`, then `OutcomesReport`)
  and per version. Check the Outcomes Report and link the Research Plan beside
  it. CrossRef search can miss a stage (for example the Jaeger Outcomes Report),
  so scan the neighbouring article numbers on
  `https://lifecycle-flax.fly.dev/journal/articles/<N>/index.html`.
- **Read the landing page's embedded JSON** (`const submission = {…}`), not the
  rendered text. Its `type`, `status`, `code`, `data`, `materials`,
  `registration` and `$authors` fields hold the code and data links. An ORCID
  there can be wrong (one page had an author's ORCID swapped with a co-author's),
  so CrossRef or the ORCID API is the reference.
- **Resolve OSF links** with `https://api.osf.io/v2/guids/<id>/`. Five-character
  links are often single files in a project, not projects.
- **Next certificate ID**: one more than the highest `| YYYY-NNN` suffix
  among the titles of **all** register issues, open and closed
  (`gh api 'repos/codecheckers/register/issues?state=all&per_page=100' --paginate --jq '.[].title'`).
  Not `register.csv`: it lists finished checks only, so IDs already given
  to checks in progress are missing from it.
- **Create issues** with
  `gh api repos/codecheckers/register/issues -X POST --input <json>`, a JSON
  file carrying `title`, `body`, `labels` and `assignees`.

## Suggesting codecheckers

The local Chekhov checkout (`../chekhov/`) previews the bot's reply and
posts nothing:

```bash
cd ../chekhov && go build -o <scratchpad>/chekhov ./cmd/chekhov
printf '@chekhovbot suggest codecheckers <DOI or github::owner/repo>\n\n<pasted hints>\n' \
  | CHEKHOV_TARGET_REPO=codecheckers/codecheckers CHEKHOV_GH_ACCESS_TOKEN=$(gh auth token) \
    <scratchpad>/chekhov comment --as nuest --online -
```

- Without `CHEKHOV_TARGET_REPO` it reads the stale lists in the testing
  register. Check that the reply says about 87 codecheckers were considered.
- Without the token, it refuses with "`@chekhovbot suggest` is for editors".
- It reads no languages from OSF or Zenodo (codecheckers/chekhov#58), so paste
  the deposit's file names under the command.
- The ranking ignores how recently someone signed up. Sign-up dates come from
  the "Register as codechecker" issues in `codecheckers/codecheckers`
  (`gh api 'repos/codecheckers/codecheckers/issues?state=all&sort=created'`).
  Newcomers are preferred and have to be promoted by hand.
- Invitation comment: @-mention the codechecker, ask whether they are
  interested and can finish by the end of the month, and offer an onboarding
  call with Daniel.

## Conventions

- Commit messages: terse, lowercase, reference GitHub issues with `closes #N`; for a new certificate: `add YYYY-NNN, closes #N`. Several at once: `add certificates YYYY-NNN and YYYY-MMM, rel #N, rel #M`
- Certificate IDs: `YYYY-NNN` format (e.g., `2026-001`)
- Branch: `master` (not `main`). Remotes: `upstream` and `nuest`
- `docs/` contains generated HTML, JSON, markdown — per-certificate pages, codechecker pages, venue pages, sitemap, robots.txt
- Register JSON API: `docs/register.json` (full), `docs/featured.json` (last 10)
- API keys live in the git-ignored `.env` (see `.env.example`); `make env` shows which are set without printing them
