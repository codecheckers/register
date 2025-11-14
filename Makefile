default: render

version:
	R -q -e "library('codecheck'); sessionInfo();"

install:
	R -q -e "remotes::install_github('codecheckers/codecheck');"

install_local:
	R -q -e "devtools::install('../codecheck', upgrade = 'never');"

render: version
	R -q -e "codecheck::register_render(parallel = TRUE); warnings();"

render_latest: clean
	R -q -e "register = read.csv('register.csv', as.is = TRUE, comment.char = '#'); codecheck::register_check(from = nrow(register), to = nrow(register) - 2);"

clean: version
	rm -r -f .cache/R
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
