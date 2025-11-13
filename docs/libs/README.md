# External Libraries

This directory contains CSS and JavaScript libraries used by the CODECHECK register.
These libraries are downloaded and stored locally to ensure reproducibility and
remove dependency on external CDNs.

## Installed Libraries

### Bootstrap 5.3.3

- **Description**: Front-end framework for web development
- **License**: MIT
- **License URL**: https://github.com/twbs/bootstrap/blob/v5.3.3/LICENSE
- **Configured**: 2025-11-13

### Font Awesome 4.7.0

- **Description**: Icon toolkit
- **License**: OFL-1.1 (fonts), MIT (CSS)
- **License URL**: https://fontawesome.com/license/free
- **Configured**: 2025-11-13

### Academicons 1.9.4

- **Description**: Academic icons for LaTeX, XeLaTeX, web, and more
- **License**: OFL-1.1 (fonts), MIT (CSS)
- **License URL**: https://github.com/jpswalsh/academicons/blob/master/LICENSE
- **Configured**: 2025-11-13

## Updating Libraries

To update these libraries, run:
```r
codecheck::setup_external_libraries(force = TRUE)
```

## Provenance

Full provenance information is maintained in `PROVENANCE.csv` in this directory.
