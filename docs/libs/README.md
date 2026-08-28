# External Libraries

This directory contains CSS and JavaScript libraries used by the CODECHECK register.
These libraries are downloaded and stored locally to ensure reproducibility and
remove dependency on external CDNs.

## Installed Libraries

### Bootstrap 5.3.3

- **Description**: Front-end framework for web development
- **License**: MIT
- **License URL**: https://github.com/twbs/bootstrap/blob/v5.3.3/LICENSE
- **Configured**: 2026-08-26

### Font Awesome 4.7.0

- **Description**: Icon toolkit
- **License**: OFL-1.1 (fonts), MIT (CSS)
- **License URL**: https://fontawesome.com/license/free
- **Configured**: 2026-08-26

### Academicons 1.9.4

- **Description**: Academic icons for LaTeX, XeLaTeX, web, and more
- **License**: OFL-1.1 (fonts), MIT (CSS)
- **License URL**: https://github.com/jpswalsh/academicons/blob/master/LICENSE
- **Configured**: 2026-08-26

### Chart.js 4.4.4

- **Description**: Charting library used by the statistics dashboard
- **License**: MIT
- **License URL**: https://github.com/chartjs/Chart.js/blob/v4.4.4/LICENSE.md
- **Configured**: 2026-08-27

## Updating Libraries

To update these libraries, run:
```r
codecheck::setup_external_libraries(force = TRUE)
```

## Provenance

Full provenance information is maintained in `PROVENANCE.csv` in this directory.
