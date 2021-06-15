default: render

render:
	R -q -e "codecheck::register_render()"

clean:
	rm -r -f .cache/R
	R -q -e "codecheck::register_clear_cache();"
