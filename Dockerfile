# Dockerfile to render the CODECHECK register, see https://github.com/codecheckers/register
FROM rocker/verse:4.2

RUN apt-get update -qq && apt-get -y --no-install-recommends install \
  # needed for zen4R's dependency 'keyring'
  libsecret-1-dev

ENV R_REMOTES_UPGRADE="never"

RUN R -q -e 'remotes::install_github("codecheckers/codecheck")'

WORKDIR /register

ENTRYPOINT [ "R" ]

# set R.cache path to avoid interactive prompt
CMD [ "-e", "options(\"R.cache.rootPath\" = \"/tmp\"); codecheck::register_render(); warnings()'" ]

LABEL maintainer = "Daniel Nüst <daniel.nuest@uni-muenster.de>"

# Usage, from local copy of the register repository
# docker build --tag codecheckers-register .
# docker run --rm -it --user $UID -v $(pwd):/register codecheckers-register