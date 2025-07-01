default: render

version:
	R -q -e "library('codecheck'); sessionInfo();"

install:
	R -q -e "remotes::install_github('codecheckers/codecheck');"

install_local:
	R -q -e "devtools::install('../codecheck', upgrade = 'never');"

render: version
	R -q -e "codecheck::register_render(); warnings();"

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
	docker build --tag codecheckers/register:latest --no-cache .
image_push: image_build
	docker push codecheckers/register:latest
.phony: image_build, image_push

image_render:
	docker pull codecheckers/register:latest
	docker run --rm -it --user rstudio -v $(shell pwd):/register codecheckers/register:latest