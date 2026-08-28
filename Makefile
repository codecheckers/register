default: render

# Local API keys, see .env.example. Optional, the file is git-ignored and every
# variable can also be passed per invocation, e.g. make render OPENALEX_API_KEY=abc
-include .env

ifdef OPENALEX_API_KEY
export OPENALEX_API_KEY
endif

ifdef ZENODO_TOKEN
export ZENODO_TOKEN
endif

version:
	R -q -e "library('codecheck'); sessionInfo();"

# show which API keys the render targets will use, without printing them
env:
	@echo "OPENALEX_API_KEY: $(if $(OPENALEX_API_KEY),set ($(shell echo -n '$(OPENALEX_API_KEY)' | wc -c) characters),not set, using the anonymous OpenAlex quota)"
	@echo "GITHUB_PAT:       $(if $(shell grep -s GITHUB_PAT ~/.Renviron),set in ~/.Renviron,not found in ~/.Renviron)"
	@echo "ZENODO_TOKEN:     $(if $(ZENODO_TOKEN),set ($(shell echo -n '$(ZENODO_TOKEN)' | wc -c) characters),not set, needed only for the zenodo_* targets)"

# same installation path as the Dockerfile, so the local environment matches
# the codecheckers/register image
install:
	R -q -e "pak::pak('codecheckers/codecheck');"

install_local:
	R -q -e "devtools::install('../codecheck', upgrade = FALSE);"

# CHECK_ZENODO=0 skips the Zenodo curation policy audit, which costs one
# (cached) API request per certificate on a cold render
# PRUNE_STALE=1 actually removes a certificate's OpenAlex ID/abstract when this
# render's live lookup conclusively confirms it is no longer available -
# routine renders never do this, a lookup that merely failed always keeps the
# previous value regardless of this flag, see resolve_external_field()
render: version env
	R -q -e "codecheck::register_render(parallel = TRUE, check_zenodo_policy = $(if $(filter 0,$(CHECK_ZENODO)),FALSE,TRUE), prune_unavailable_metadata = $(if $(filter 1,$(PRUNE_STALE)),TRUE,FALSE));"

stats: version
	R -q -e "codecheck::register_update_stats();"

cert:
ifndef CERT_ID
	$(error Usage: make cert CERT_ID=2024-017)
endif
	R -q -e "codecheck::register_render_cert('$(CERT_ID)');"

render_latest: clean
	R -q -e "register = read.csv('register.csv', as.is = TRUE, comment.char = '#'); codecheck::register_check(from = nrow(register), to = nrow(register) - 2);"

clean: version
	rm -r -f .cache/R
	find docs/certs -type d -name "libs" -exec rm -rf {} + 2>/dev/null || true
	R -q -e "codecheck::register_clear_cache();"

check: clean
	R -q -e "codecheck::register_check(); warnings();"

check_latest: clean
	R -q -e "register = read.csv('register.csv', as.is = TRUE, comment.char = '#'); codecheck::register_check(from = nrow(register), to = nrow(register) - 5);"

# audit a published certificate record against the CODECHECK Zenodo community
# curation policy, https://zenodo.org/communities/codecheck/curation-policy
# Read-only, no token needed.
zenodo_check:
ifndef CERT_ID
	$(error Usage: make zenodo_check CERT_ID=2026-023)
endif
	R -q -e "codecheck::check_zenodo_record('$(CERT_ID)');"

# propose the metadata corrections for a published certificate record. Dry run
# by default, pass APPLY=1 to write the changes to Zenodo, which needs a
# ZENODO_TOKEN with write access (see .env.example).
zenodo_curate:
ifndef CERT_ID
	$(error Usage: make zenodo_curate CERT_ID=2026-023 [APPLY=1])
endif
	R -q -e "codecheck::curate_zenodo_record('$(CERT_ID)', dry_run = $(if $(APPLY),FALSE,TRUE));"
# curate Zenodo records of the register: only the mechanical corrections,
# whose target value follows from the certificate ID or codecheck.yml. Dry run
# by default, pass APPLY=1 to write. Excludes creator names, which need review.
# CERTS=2020-001,2024-023 restricts the run to those certificates.
zenodo_curate_all:
	R -q -e "\
	  reg <- read.csv('register.csv', as.is = TRUE, comment.char = '#'); \
	  full <- jsonlite::fromJSON('docs/register.json'); \
	  tbl <- merge(data.frame(Certificate = full[['Certificate ID']], Report = full[['Report']], stringsAsFactors = FALSE), \
	               data.frame(Certificate = reg[['Certificate']], Repository = reg[['Repository']], stringsAsFactors = FALSE), by = 'Certificate'); \
	  certs <- trimws(strsplit('$(CERTS)', ',')[[1]]); \
	  if (any(nchar(certs) > 0)) tbl <- tbl[tbl[['Certificate']] %in% certs, ]; \
	  res <- codecheck::curate_register_zenodo_records(tbl, dry_run = $(if $(APPLY),FALSE,TRUE)); \
	  write.csv(res, 'zenodo_curation_result.csv', row.names = FALSE);"
.phony: zenodo_check, zenodo_curate, zenodo_curate_all

# automated build is active via GitHub Action
image_build:
	docker build --tag codecheckers/register:latest --no-cache --build-arg GITHUB_PAT=@bash -c "source ~/.Renviron && echo \$\$GITHUB_PAT" .

# use the local GITHUB_PAT to avoid rate limits
image_build_local: $(eval SHELL:=/bin/bash)
	source ~/.Renviron && docker build --tag codecheckers/register:latest --no-cache --build-arg GITHUB_PAT=$$GITHUB_PAT .

image_push: image_build
	docker push codecheckers/register:latest
.phony: image_build, image_push

image_render: $(eval SHELL:=/bin/bash)
	docker pull codecheckers/register:latest
	source ~/.Renviron && docker run --rm -it --user rstudio -v $(shell pwd):/register:rw -e GITHUB_PAT=$$GITHUB_PAT codecheckers/register:latest

# serve the docs/ directory locally using nginx on port 80
serve:
	docker run --rm -d --name codecheck-register-nginx -p 80:80 -v $(shell pwd)/docs:/usr/share/nginx/html:ro nginx:alpine
	@echo "Serving docs/ at http://localhost"
	@echo "Run 'make serve-stop' to stop the server"

# stop the local nginx server
serve-stop:
	docker stop codecheck-register-nginx
	@echo "Stopped nginx server"
.phony: serve, serve-stop
