# Dockerfile to render the CODECHECK register, see https://github.com/codecheckers/register
FROM rocker/verse:4.5

RUN apt-get update -qq && apt-get -y --no-install-recommends install \
  # needed for zen4R's dependency 'keyring'
  libsecret-1-dev \
  # for pdftools
  libpoppler-cpp-dev

# rocker images no longer ship 'remotes', but they do ship 'pak'
RUN R -q -e 'pak::pak("codecheckers/codecheck")'

WORKDIR /register

ENTRYPOINT [ "R" ]

# set R.cache path to avoid interactive prompt
CMD [ "-e", "sessionInfo(); options(\"R.cache.rootPath\" = \"/tmp\"); rl <- gh::gh_rate_limit(); cat(\"GitHub API usage: limit\", rl$limit, \", remaining\", rl$remaining, \", reset\", format(rl$reset, \"%Y-%m-%d %H:%M:%S %Z\"), \"\\n\"); codecheck::register_render(); warnings()'" ]

LABEL maintainer="Daniel Nüst <daniel.nuest@tu-dresden.de>"

# Usage, from local copy of the register repository
# docker build --tag codecheckers-register .
# docker run --rm -it --user rstudio -v $(pwd):/register -e GITHUB_PAT=$GITHUB_PAT codecheckers-register