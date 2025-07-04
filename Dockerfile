# Dockerfile to render the CODECHECK register, see https://github.com/codecheckers/register
FROM rocker/verse:4.5

RUN apt-get update -qq && apt-get -y --no-install-recommends install \
  # needed for zen4R's dependency 'keyring'
  libsecret-1-dev \
  # for pdftools
  libpoppler-cpp-dev

ENV R_REMOTES_UPGRADE="never"

RUN R -q -e 'remotes::install_github("codecheckers/codecheck")'

WORKDIR /register

ENTRYPOINT [ "R" ]

# set R.cache path to avoid interactive prompt
CMD [ "-e", "sessionInfo(); options(\"R.cache.rootPath\" = \"/tmp\"); cat(\"GitHub API usage:\", toString(names(gh::gh_rate_limit())), \" : \", toString(gh::gh_rate_limit()), \"\\n\"); codecheck::register_render(); warnings()'" ]

LABEL maintainer="Daniel Nüst <daniel.nuest@tu-dresden.de>"

# Usage, from local copy of the register repository
# docker build --tag codecheckers-register .
# docker run --rm -it --user rstudio -v $(pwd):/register codecheckers-register