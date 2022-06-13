default: render

version:
	R -q -e "library('codecheck'); sessionInfo();"

render: version
	R -q -e "codecheck::register_render()"

clean: version
	rm -r -f .cache/R
	R -q -e "codecheck::register_clear_cache();"

check: clean
	R -q -e "codecheck::register_check(); warnings();"

# automated builds not available on Docker Hub anymore
image_build:
	docker build --tag codecheckers/register:latest --no-cache .
.phone: image_build

image_push: image_build
	docker push codecheckers/register:latest
.phony: image_push
