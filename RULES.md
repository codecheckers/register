# CODECHECK validation rules

`rules-1.0.yml` and `rules-2.0.yml` are the **authoritative lists** of the rules
that CODECHECK tooling validates, one file per version of the
[configuration file specification](https://codecheck.org.uk/spec/config/). Every implementation refers to these identifiers, so that two
implementations of the same rule can be compared, and a divergence found by
grepping rather than by reading both codebases.

## Identifier scheme

```
CC-<AREA>-<NNN>
```

| Area | Meaning |
|---|---|
| `CFG` | Structure and content of `codecheck.yml` |
| `MET` | External identifiers and metadata (ORCID, Crossref) |
| `BUN` | The CODECHECK bundle and the repository under check |
| `REP` | Certificate/report and its archive record |
| `REG` | The register entry itself |

Rules:

- **Identifiers are permanent.** A number is never reused and never renumbered.
- A rule that is withdrawn keeps its identifier with `status: deprecated`.
- Splitting a rule creates new identifiers; the old one is deprecated and its
  description says what replaced it.
- `severity` is a property of the rule, not of the identifier: `error` for a
  MUST in the specification, `warning` for a SHOULD, `info` for advice.

## Severity follows the specification's own keywords

The specification uses RFC 2119 keywords, and severity is derived from them
mechanically — it is not a judgement about how annoying a problem is:

| In the specification | Severity | Effect |
|---|---|---|
| MUST / MUST NOT / REQUIRED | `error` | The configuration is invalid |
| SHOULD / SHOULD NOT / RECOMMENDED | `warning` | Reported, does not invalidate |
| MAY / OPTIONAL / "ideally" | `info` | Advisory only, never blocks |

A rule not derived from the specification carries `reference: practice` and is a
`warning` when the community treats it as expected, `info` when it is advice.

## Versions

One file per specification version; the identifier of a rule stays the same
across versions, so `diff` shows exactly what a new specification version
hardened.

| File | Specification |
|---|---|
| `rules-1.0.yml` | [1.0](https://codecheck.org.uk/spec/config/1.0/), the published version |
| `rules-2.0.yml` | [2.0](https://codecheck.org.uk/spec/config/2.0/), in preparation; absorbs the former 1.x draft |

**2.0 hardens nine rules** and **adds three**. `diff rules-1.0.yml rules-2.0.yml`
shows exactly this:

| Rule | 1.0 | 2.0 |
|---|---|---|
| `CC-CFG-016` paper-present | warning | error |
| `CC-CFG-017` paper-title | warning | error |
| `CC-CFG-018` paper-authors | warning | error |
| `CC-CFG-019` paper-author-name | warning | error |
| `CC-CFG-020` paper-author-orcid | warning | error |
| `CC-CFG-021` paper-reference | warning | error |
| `CC-CFG-024` summary-present | info | error |
| `CC-CFG-025` certificate-present | info | error |
| `CC-CFG-027` reference-is-url | info | warning |

New in 2.0, for the `reference-other` list — previous or otherwise related
references to the work, a plain list for now:

| Rule | Severity | |
|---|---|---|
| `CC-CFG-029` reference-other-is-list | error | when present, it is a sequence |
| `CC-CFG-030` reference-other-item-form | warning | each entry is a resolvable URL, preferably a DOI |
| `CC-MET-009` reference-other-resolves | warning | each entry resolves |

The `reference` wording follows
[discussion#3](https://github.com/codecheckers/discussion/issues/3#issuecomment-2357812608):
a reference MUST be provided, it SHOULD be a resolvable URL, and a DOI is
preferred for long-term availability. Free text remains valid, but tools do not
extract a URL from surrounding text — which is what `CC-CFG-027` reports.

A direct PDF link as the `reference` is a warning, `CC-CFG-022`, because such
links break and carry no machine-readable metadata. Where the link is a
[Wayback Machine](https://web.archive.org/) snapshot it is information only,
`CC-CFG-031`, since archiving is what both specification versions recommend when
no DOI or landing page exists. Both rules are in `rules-1.0.yml` and
`rules-2.0.yml`; the pair is a severity split, not a 2.0 addition.

The draft 1.x specification is absorbed into 2.0 and no longer exists
separately; its one substantive change, raising the author ORCID from SHOULD to
MUST, is `CC-CFG-020`.

## Fields

Each entry in the `rules:` list has the same seven keys, in this order:

| Key | Meaning |
|---|---|
| `id` | `CC-AREA-NNN`, permanent |
| `name` | Short kebab-case handle, used in code symbols |
| `area` | `config`, `metadata`, `bundle`, `report`, `register` |
| `severity` | `error`, `warning`, `info` — see above |
| `status` | `active`, `deprecated` |
| `reference` | Specification anchor, the R function that first implemented the rule, or `practice` |
| `description` | One line in plain language; quoted, because several contain a colon |

Each file also carries `version` for the catalogue format, `spec_version` for
the specification it describes, and an `updated` date. Rules are grouped by area
with a comment line and ordered by identifier.

YAML rather than CSV so that a description can grow into a paragraph without
escaping games, and because both implementations already parse YAML — the
format of `codecheck.yml` itself.

## Use in implementations

Every implementation tags its validator with the identifier, so the two can be
diffed mechanically.

**Go** (`codecheckers/chekhov`):

```go
// Rule: CC-CFG-005 manifest-item-file
func checkManifestItemFile(c *Config) []Finding { ... }
```

**R** (`codecheck` package):

```r
check_manifest_item_file <- function(config) {
  # Rule: CC-CFG-005 manifest-item-file
  ...
}
```

The identifier goes in a plain comment in both languages, not in a roxygen tag
or a struct annotation, so that one grep covers both implementations.

A CI job on this repository can then list which identifiers each implementation
covers and report the difference — the rules present in one and missing in the
other, and any whose severity disagrees.

## Changing the rules

The rule files are the source of truth. Add or deprecate a rule here first, then
update the implementations. A rule that exists only in code is a bug.
