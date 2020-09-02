# Register of CODECHECK certificates

See the register online at [**https://codecheck.org.uk/register/**](https://codecheck.org.uk/register/).

## Files in this repository

[`register.csv`](register.csv) is the main file to edit to put a new certificate into the register.

[`docs/register.md`](register.md), [`docs/register.json`](docs/register.json),  and [`docs/index.html`](https://codecheck.org.uk/register) are processed, human-readable and machine-readable outputs based on the register with some additional information.
Do not edit these files!
They must be regenerated with `R -q -e "codecheck::register_render()"` of the [`codecheck` R package](https://github.com/codecheckers/codecheck) after each update of the main register file.
You can check the configuration files with `R -q -e "codecheck::register_check()"` and clear the cache (in case you made a recent change to an online repo) with `R -q -e "codecheck::register_clear_cache()"`

To fix problems with hitting the GitHub API rate limit, go to [your PAT page](https://github.com/settings/tokens) and save a PAT in the environment variable `GITHUB_PAT` to the file `.Renviron` next to this README file.

## License

The data in this repository is published under a [Open Data Commons Attribution License](https://opendatacommons.org/licenses/by/summary/) (ODC-BY).

The code and documentation in this repository is published under the [MIT License](https://choosealicense.com/licenses/mit/).

See file [`LICENSE`](LICENSE) for details.

------

[About CODECHECK](https://codecheck.org.uk/)
