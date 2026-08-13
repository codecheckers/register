default: render

# Local API keys, see .env.example. Optional, the file is git-ignored and every
# variable can also be passed per invocation, e.g. make render OPENALEX_API_KEY=abc
-include .env

ifdef OPENALEX_API_KEY
export OPENALEX_API_KEY
endif

version:
	R -q -e "library('codecheck'); sessionInfo();"

# show which API keys the render targets will use, without printing them
env:
	@echo "OPENALEX_API_KEY: $(if $(OPENALEX_API_KEY),set ($(shell echo -n '$(OPENALEX_API_KEY)' | wc -c) characters),not set, using the anonymous OpenAlex quota)"
	@echo "GITHUB_PAT:       $(if $(shell grep -s GITHUB_PAT ~/.Renviron),set in ~/.Renviron,not found in ~/.Renviron)"

install:
	R -q -e "remotes::install_github('codecheckers/codecheck');"

install_local:
	R -q -e "devtools::install('../codecheck', upgrade = FALSE);"

render: version env
	R -q -e "codecheck::register_render(parallel = TRUE);"

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
