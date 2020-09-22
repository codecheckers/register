# Register of CODECHECK certificates

See the register online at [**https://codecheck.org.uk/register/**](https://codecheck.org.uk/register/).

## Files in this repository

[`register.csv`](register.csv) is the main file to edit to put a new certificate into the register.

[`docs/register.md`](register.md), [`docs/register.json`](docs/register.json),  and [`docs/index.html`](https://codecheck.org.uk/register) are processed, human-readable and machine-readable outputs based on the register with some additional information.
Do not edit these files!
They must be regenerated with `R -q -e "codecheck::register_render()"` of the [`codecheck` R package](https://github.com/codecheckers/codecheck) after each update of the main register file.
You can check the configuration files with `R -q -e "codecheck::register_check(); warnings()"` and clear the cache (in case you made a recent change to an online repo) with `R -q -e "codecheck::register_clear_cache()"`

To fix problems with hitting the GitHub API rate limit, go to [your PAT page](https://github.com/settings/tokens) and save a PAT in the environment variable `GITHUB_PAT` to the file `.Renviron` next to this README file.

## Editing the register

The main register file is a simple CSV file, which connects the pieces published elsewhere to create a complete metadata set for each CODECHECK.
The CSV file should not unneedingly replicate information from elsewhere, especially from the CODECHECK configuration files (i.e., `codecheck.yml`).
Here are some possible values or rules for the specific columns in the file:

- `Certificate`: the certificate number
- `Repository`: qualified reference to the repository where the `codecheck.yml` file can be retrieved; the file must be in the project "root"; supported types and examples:
  - `github::` for referencing a GitHub repository using `org/name`, e.g., `github::codecheckers/Piccolo-2020` from codecheckers organisation
  - `osf::` for referencing an OSF project using the project identifier, e.g.,  `osf::ZTC7M`
- `Type`: type of the check, e.g., solicited as part of peer review in a journal or conference, or initiated from the community; possible values:
  - `community` = check initiated independently by community members and following the [CODECHECK community process guide](https://codecheck.org.uk/guide/community-process); may be qualified further, e.g., for preprints as `community (preprint)`
  - `journal (<journal abbreviation>)` = check conducted as part of a peer review process with a scientific journal, including a reference to the check in the published article; the journal abbreviation uses the [ISO 4](https://en.wikipedia.org/wiki/ISO_4) standard name for the journal, using common capitalization and omitting full stops, for example `J Geogr Syst` or `GigaScience` (find the correct name via Wikipedia or the journal website)
  - `conference (<conf name>)` = check conducted as part of a peer review process at a scientific conference, e.g., `conference (AGILEGIS)`
- `Issue`: number of the issue in the register project where the CODECHECK is managed (informative mostly, not for metadata retrieval)

## License

The data in this repository is published under a [Open Data Commons Attribution License](https://opendatacommons.org/licenses/by/summary/) (ODC-BY).

The code and documentation in this repository is published under the [MIT License](https://choosealicense.com/licenses/mit/).

See file [`LICENSE`](LICENSE) for details.

------

[About CODECHECK](https://codecheck.org.uk/)
