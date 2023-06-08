# Register of CODECHECK certificates

See the register online at [**https://codecheck.org.uk/register/**](https://codecheck.org.uk/register/).

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.4059767.svg)](https://doi.org/10.5281/zenodo.4059767)

## Editing the register

The main register file is a simple CSV file, `register.csv` which connects the pieces published elsewhere to create a complete metadata set for each CODECHECK.
The CSV file should not unneedingly replicate information from elsewhere, especially from the CODECHECK configuration files (i.e., `codecheck.yml`).
Here are some possible values or rules for the specific columns in the file:

- `Certificate`: the certificate number
- `Repository`: qualified reference to the repository where the `codecheck.yml` file can be retrieved; the file must be in the project "root"; supported types and examples:
  - `github::` for referencing a GitHub repository using `org/name`, e.g., `github::codecheckers/Piccolo-2020` from codecheckers organisation
  - `osf::` for referencing an OSF project using the project identifier, e.g.,  `osf::ZTC7M`
- `Type`: type of the check, e.g., solicited as part of peer review in a journal or conference, or initiated from the community; possible values:
  - `community` = check initiated independently by community members and following the [CODECHECK community workflow guide](https://codecheck.org.uk/guide/community-workflow); may be qualified further, e.g., for preprints as `community (preprint)`
  - `journal (<journal abbreviation>)` = check conducted as part of a peer review process with a scientific journal, including a reference to the check in the published article; the journal abbreviation uses the [ISO 4](https://en.wikipedia.org/wiki/ISO_4) standard name for the journal, using common capitalization and omitting full stops, for example `J Geogr Syst` or `GigaScience` (find the correct name via Wikipedia or the journal website)
  - `conference (<conf name>)` = check conducted as part of a peer review process at a scientific conference, e.g., `conference (AGILEGIS)`
- `Issue`: number of the issue in the register project where the CODECHECK is managed (informative mostly, not for metadata retrieval)

To update the register, simply edit the `register.csv` file and submit the change.
A GitHub Action will apply the process outlined below for manual rendering to update the different representations of the register, including the website, in case the main register file changes.

## Deposit/archive

This repository is archived manually, in regular intervals, on Zenodo using the [GitHub-Zenodo-Integration](https://guides.github.com/activities/citable-code/).
To deposit a new version on Zenodo, create a new release following the naming scheme of previous releases.
Then, go to the new record and manually make the following changes:

- add the record to [the CODECHECK community](https://zenodo.org/communities/codecheck/) (if not already included)
- change the record type to "Dataset"
- update the ORCIDs and affiliations of authors
- set the license to "CC BY SA 4.0 international"
- update the Desription text (see previous records)
- add https://codecheck.org.uk/register/ as a related identifier with "is new version of this upload"

## Files in this repository

- [`register.csv`](register.csv): the main file to edit to put a new certificate into the register
- [`Makefile`](Makefile): common commands for managing the register
- [`Dockerfile`](Dockerfile): Dockerfile for building and image to use in the GitHub action; needs to be build and pushed to Docker Hub
- [`docs/register.md`](register.md): Markdown table of the register with additional metadata for checks
- [`docs/register.json`](docs/register.json) and [`docs/featured.json`](docs/featured.json): JSON file with additional metadata for checks, whereas the "featured" file only contains the last ten codechecks; use for integration of CODECHECK metadata in third party services, APIs, etc.; public links: [https://codecheck.org.uk/register/register.json](https://codecheck.org.uk/register/register.json) and [https://codecheck.org.uk/register/featured.json](https://codecheck.org.uk/register/featured.json)
- [`docs/index.html`](https://codecheck.org.uk/register): HTML rendering of the extended register

The above files are human-readable and machine-readable representations based on the register and metadata from the `codecheck.yml` files.

_Do not edit any file in the `docs` directory by hand! Edit only `register.csv`._

## Manual register rendering and checking

The representations above can also be generated manually using the following command from the [`codecheck` R package](https://github.com/codecheckers/codecheck):

```bash
# R -q -e "remotes::install_github('codecheckers/codecheck')"

R -q -e "codecheck::register_render(); warnings()"
```

You can also check the configuration files with

```bash
R -q -e "codecheck::register_check(); warnings()"
```

and clear the cache (in case you made a recent change to an online repo) with `R -q -e "codecheck::register_clear_cache()"`.

To fix problems with hitting the GitHub API rate limit on local register management, go to [your PAT page](https://github.com/settings/tokens) and save a PAT in the environment variable `GITHUB_PAT` to the file `.Renviron` next to this README file.

## License

The data in this repository is published under a [Open Data Commons Attribution License](https://opendatacommons.org/licenses/by/summary/) (ODC-BY).

The code and documentation in this repository is published under the [MIT License](https://choosealicense.com/licenses/mit/).

See file [`LICENSE`](LICENSE) for details.

------

[About CODECHECK](https://codecheck.org.uk/)
