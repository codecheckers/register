# Register of CODECHECK certificates

See the register online at [**https://codecheck.org.uk/register/**](https://codecheck.org.uk/register/).

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.4059767.svg)](https://doi.org/10.5281/zenodo.4059767)

## Editing the register

The main register file is a simple CSV file, `register.csv` which connects the pieces published elsewhere to create a complete metadata set for each CODECHECK.
The CSV file should not unneedingly replicate information from elsewhere, especially from the CODECHECK configuration files (i.e., `codecheck.yml`).
Here are some possible values or rules for the specific columns in the file:

- `Certificate`: the certificate number or certificate identifier in the form `YYYY-NNN` (e.g., `2020-001`), which must match the ; if we ever need to write down a range, we seperate the first and last complete ID by a "/", e.g., `2025-111/2025-222`
- `Repository`: qualified reference to the repository where the `codecheck.yml` file can be retrieved; the file must be in the project "root"; supported types and examples:
  - `github::` for referencing a GitHub repository using `org/name`, e.g., `github::codecheckers/Piccolo-2020` from codecheckers organisation; you may also append a path seperated by a pipe character `|` within a GitHub repository if the `codecheck.yml` file is not in the root, e.g., `github::reproducible-agile/reviews-2025|reports/08`
  - `osf::` for referencing an OSF project using the project identifier, e.g., `osf::ZTC7M`
  - `zenodo::` for referencing a Zenodo record using the record identifier, e.g., `zenodo::1234567`
  - `gitlab::` for referencing a GitLab repository using `org/name`, e.g., `gitlab::codecheckers/Piccolo-2020`
- `Type`: type of the check, e.g., solicited as part of peer review in a journal or conference, or initiated from the community; possible values:
  - `community` = check initiated independently by community members and following the [CODECHECK community workflow guide](https://codecheck.org.uk/guide/community-workflow); may be qualified further with a venue
  - `journal` = check conducted as part of a peer review process with a scientific journal, including a reference to the check in the published article
  - `conference` = check conducted as part of a peer review process at a scientific conference
  - `institution` = check conducted as part of a peer review process at an institution
- `Venue`: name of the journal, conference, or institution where the check was conducted, including specifications such as `preprint` or `in press`
  - the journal abbreviation uses the [ISO 4](https://en.wikipedia.org/wiki/ISO_4) standard name for the journal, using common capitalization and omitting full stops, for example `J Geogr Syst` or `GigaScience` (find the correct name via Wikipedia or the journal website)
- `Issue`: number of the issue in the register project where the CODECHECK is managed (informative mostly, not for metadata retrieval)

To update the register, edit the `register.csv` file and submit the change.
You can add preliminary information by starting the line with the comment character `#`, this row will be ignored.

A GitHub Action will apply the process outlined below for manual rendering to update the different representations of the register, including the website, in case the main register file changes.

**Note:** The GitHub action requieres a `PAT` token to be added, because the default per-action-run token is not used by the R code that renders the package.
See the docs about manual rendering below for details.

## Deposit/archive

This repository is archived *manually*, in irregular intervals, on Zenodo using the [GitHub-Zenodo-Integration](https://guides.github.com/activities/citable-code/).
To deposit a new version on Zenodo, create a new release following the naming scheme of previous releases.
Then, go to the new record and manually make the following changes:

- add the record to [the CODECHECK community](https://zenodo.org/communities/codecheck/) (if not already included)
- change the record type to "Dataset"
- update the ORCIDs and affiliations of authors
- set the license to "Open Data Commons Attribution License"
- update the Desription text (see previous records)
- add <https://codecheck.org.uk/register/> as a related identifier with "is new version of this upload"

In the future, these steps may be automated, see [issue #34](https://github.com/codecheckers/register/issues/34).

## Files in this repository

- [`register.csv`](register.csv): the main file to edit to put a new certificate into the register
- [`Makefile`](Makefile): common commands for managing the register
- [`Dockerfile`](Dockerfile): Dockerfile for building and image to use in the GitHub action; needs to be build and pushed to Docker Hub
- [`docs/register.md`](register.md): Markdown table of the register with additional metadata for checks
- [`docs/register.json`](docs/register.json) and [`docs/featured.json`](docs/featured.json): JSON file with additional metadata for checks, whereas the "featured" file only contains the last ten codechecks; use for integration of CODECHECK metadata in third party services, APIs, etc.; public links: [https://codecheck.org.uk/register/register.json](https://codecheck.org.uk/register/register.json) and [https://codecheck.org.uk/register/featured.json](https://codecheck.org.uk/register/featured.json)
- [`docs/index.html`](https://codecheck.org.uk/register): HTML rendering of the extended register

The above files are human-readable and machine-readable representations based on the register and metadata from the `codecheck.yml` files.

**Important**: Do not edit any file in the `docs` directory by hand! Edit only `register.csv`.

## Manual register rendering and checking

The representations above can also be generated manually using the following command from the [`codecheck` R package](https://github.com/codecheckers/codecheck):

```bash
# R -q -e "pak::pak('codecheckers/codecheck')"

R -q -e "codecheck::register_render(); warnings()"
```

You can also check the configuration files with

```bash
R -q -e "codecheck::register_check(); warnings()"
```

and clear the cache (in case you made a recent change to an online repo) with `R -q -e "codecheck::register_clear_cache()"`.

To fix problems with hitting the GitHub API rate limit on local register management, save a Personal Access Token in the environment variable `GITHUB_PAT`, see [API keys](#api-keys) below.
Alternatively, you may log into your GitHub account locally using the [GitHub CLI (`gh`)](https://cli.github.com/).

## API keys

Rendering the register queries a number of external APIs.
None of them is required to render, but without them you will hit rate limits, and entries can end up missing metadata.

| Variable | Used for | How to get it |
| --- | --- | --- |
| `GITHUB_PAT` | Reading `codecheck.yml` files and issues from GitHub. Most register entries are GitHub repositories, so without a token you hit the rate limit quickly. | [Your PAT page](https://github.com/settings/tokens), no scopes needed for public repositories |
| `OPENALEX_API_KEY` | Looking up the OpenAlex ID and the abstract of each checked paper. Without a key all requests share a small anonymous daily quota that a full render exhausts, after which certificates render without their OpenAlex ID. A free key raises the quota tenfold. | [OpenAlex](https://openalex.org/), see the [API documentation](https://help.openalex.org/api) |
| `ORCID_TOKEN` | Validating codechecker and author ORCIDs in `codecheck::register_check()`, not needed for rendering. | `rorcid::orcid_auth()`, see the [rorcid documentation](https://docs.ropensci.org/rorcid/) |

Zenodo, OSF, CrossRef and ResearchEquals are queried anonymously and need no configuration.

Two further credentials are not used for rendering, but for the targets that *write* somewhere, and they live only in `.env`:

| Variable | Used for | How to get it |
| --- | --- | --- |
| `ZENODO_TOKEN` | `make zenodo_curate CERT_ID=... APPLY=1`, correcting a published certificate record against the [CODECHECK community curation policy](https://zenodo.org/communities/codecheck/curation-policy). The audit (`make zenodo_check`) is read-only and needs no token. | [Zenodo applications](https://zenodo.org/account/settings/applications/), scopes `deposit:write` and `deposit:actions` |
| `WIKIBASE_USER`, `WIKIBASE_TOKEN` | Pushing the register into <https://codecheck.wikibase.cloud>, the CODECHECK Wikibase instance ([register#50](https://github.com/codecheckers/register/issues/50)). Reading that instance and its SPARQL endpoint is anonymous. | A bot password from [`Special:BotPasswords`](https://codecheck.wikibase.cloud/wiki/Special:BotPasswords) on the instance |

A bot password is shown as a login name of the form `<account>@<bot name>` plus a 32-character password; put those into `WIKIBASE_USER` and `WIKIBASE_TOKEN` respectively.
`Special:BotPasswords` also offers a legacy form for clients that require the login name to equal the account name — username `<account>`, password `<bot name>@<the 32-character password>` — which is not what these two variables expect.

There are two places to put these variables.

**In `~/.Renviron`**, one `NAME=value` per line, which applies to every R session on your machine:

```
GITHUB_PAT=ghp_...
OPENALEX_API_KEY=...
```

**Important**: R reads only the *first* `.Renviron` it finds, checking this directory before your home directory.
So if you create a `.Renviron` next to this README, it hides `~/.Renviron` completely and every variable you need must be in the local file.
Keeping all of them in one file avoids this trap.

**In a `.env` file** next to this README, which the `Makefile` passes on to the R processes it starts.
This file is git-ignored, and unlike a local `.Renviron` it does not hide `~/.Renviron`, so it combines with the variables set there.
Copy [`.env.example`](.env.example) to `.env` and fill in the values.

Single values can also be passed per invocation:

```bash
make render OPENALEX_API_KEY=...
```

To see which keys the render targets will pick up, without printing their values:

```bash
make env
```

## Local preview with nginx

After rendering the register, you can preview the generated website locally using an nginx Docker container:

```bash
make serve
```

This will start an nginx server on port 80 serving the contents of the `docs/` directory. You can then view the register at [http://localhost](http://localhost).

To stop the server:

```bash
make serve-stop
```

**Note**: The nginx container runs in detached mode (background). If port 80 is already in use on your system, you'll need to either stop the service using that port or modify the port mapping in the Makefile.

To render the register manually in a local **Docker container**, you must mount a local `.Renviron` file with the `GITHUB_PAT` variable to not hit the GitHub API rate limit, and any other [API keys](#api-keys) you want to use.
Example (see also `Makefile`):

```bash
docker run --rm -it --user rstudio -v $PWD:/register:rw -v $HOME/.Renviron:/home/rstudio/.Renviron:ro codecheckers/register:latest
```

## Editing of codecheck.yml files

Copilot promts:

- "Update the codecheck metadata file with paper information (title, authors, ORCIDs) based on https://api.openalex.org/w4411152705 and codechecker information, including the ORCID via the profile link, and the summary and check time from https://doi.org/10.17605/OSF.IO/956a8"

## License

The data in this repository is published under a [Open Data Commons Attribution License](https://opendatacommons.org/licenses/by/summary/) (ODC-BY).

The code and documentation in this repository is published under the [MIT License](https://choosealicense.com/licenses/mit/).

See file [`LICENSE`](LICENSE) for details.

------

[About CODECHECK](https://codecheck.org.uk/)
