#!/usr/bin/env bash
# Compare the pandoc a local render would use against the one in the CI image
# (codecheckers/register:latest), which rendered everything in docs/.
#
# Pandoc 3 wraps raw-HTML inlines that pandoc 2 kept on one line, and pandoc's
# built-in <style> block changes between minor versions, so rendering with a
# different pandoc rewrites hundreds of files in docs/ with nothing but
# whitespace churn - which the next CI render flips straight back. See the
# "Pandoc version" section of the README for how to install a matching pandoc.
#
#   test/pandoc_check.sh [-i IMAGE] [-e VERSION]
#
#   -i IMAGE      CI image to read the version from
#                 (default: codecheckers/register:latest)
#   -e VERSION    fallback CI version, used only when that image is not
#                 available locally (default: 3.10)
#
# The image itself is the authority: whenever it is present the version is
# read out of it, so -e never has to be kept up to date on a machine that
# renders. The script also compares the local image with the one in the
# registry and says so when it has fallen behind, because a stale image would
# otherwise answer for a CI that has already moved on.
#
# Exits 0 when the versions match or differ only in the patch level, and 1 on
# a mismatch in the major or minor version, which does change docs/.
set -euo pipefail

cd "$(dirname "$0")/.."

IMAGE="codecheckers/register:latest"
EXPECTED="3.10"

while getopts "i:e:" opt; do
  case "$opt" in
    i) IMAGE="$OPTARG" ;;
    e) EXPECTED="$OPTARG" ;;
    *) echo "usage: $0 [-i IMAGE] [-e VERSION]" >&2; exit 2 ;;
  esac
done

# Build timestamp of the image in the registry, printed only when it can be
# read: this is a courtesy check, so no network, no curl or a private image
# must never fail the comparison we actually came for. Digests are no use
# here - a pulled image records the index digest, the registry answers with
# the platform manifest digest, and the two differ for an identical image.
remote_created() {
  local repo="${1%%:*}" tag="${1##*:}" token index manifest config
  [ "$repo" = "$tag" ] && tag="latest"
  command -v curl > /dev/null 2>&1 || return 0
  command -v python3 > /dev/null 2>&1 || return 0

  token="$(curl -s -m 10 "https://auth.docker.io/token?service=registry.docker.io&scope=repository:${repo}:pull" |
    python3 -c 'import sys,json; print(json.load(sys.stdin).get("token",""))' 2>/dev/null)" || return 0
  [ -n "$token" ] || return 0

  index="$(curl -s -m 10 -H "Authorization: Bearer $token" \
    -H "Accept: application/vnd.oci.image.index.v1+json,application/vnd.docker.distribution.manifest.list.v2+json" \
    "https://registry-1.docker.io/v2/${repo}/manifests/${tag}" |
    python3 -c 'import sys,json
d = json.load(sys.stdin)
ms = [m for m in d.get("manifests", []) if m.get("platform", {}).get("architecture") == "amd64"]
print(ms[0]["digest"] if ms else "")' 2>/dev/null)" || return 0
  [ -n "$index" ] || return 0

  manifest="$(curl -s -m 10 -H "Authorization: Bearer $token" \
    -H "Accept: application/vnd.oci.image.manifest.v1+json,application/vnd.docker.distribution.manifest.v2+json" \
    "https://registry-1.docker.io/v2/${repo}/manifests/${index}")" || return 0
  config="$(echo "$manifest" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("config",{}).get("digest",""))' 2>/dev/null)" || return 0
  [ -n "$config" ] || return 0

  curl -sL -m 10 -H "Authorization: Bearer $token" \
    "https://registry-1.docker.io/v2/${repo}/blobs/${config}" |
    python3 -c 'import sys,json; print(json.load(sys.stdin).get("created",""))' 2>/dev/null || return 0
}

# What a render actually uses: rmarkdown picks RSTUDIO_PANDOC over the pandoc
# on PATH, so ask R rather than running `pandoc --version` here.
local_version="$(R -q -s -e 'cat(format(rmarkdown::pandoc_version()))' 2>/dev/null | tail -1)"
if [ -z "$local_version" ]; then
  echo "✖ cannot determine the local pandoc version (is rmarkdown installed?)" >&2
  exit 2
fi

ci_version=""
ci_source="image $IMAGE"
image_note=""
if command -v docker > /dev/null 2>&1 && docker image inspect "$IMAGE" > /dev/null 2>&1; then
  ci_version="$(docker run --rm --entrypoint pandoc "$IMAGE" --version 2>/dev/null | head -1 | awk '{print $2}')"

  local_created="$(docker image inspect "$IMAGE" --format '{{.Created}}' 2>/dev/null || true)"
  registry_created="$(remote_created "$IMAGE" || true)"
  if [ -n "$registry_created" ] && [ -n "$local_created" ] && [ "${local_created%%.*}" != "${registry_created%%.*}" ]; then
    image_note="local image built $local_created, registry has $registry_created - run 'docker pull $IMAGE'"
  fi
fi
if [ -z "$ci_version" ]; then
  ci_version="$EXPECTED"
  ci_source="fallback version, image not available locally"
fi

echo "local pandoc: $local_version ($(R -q -s -e 'cat(rmarkdown::pandoc_exec())' 2>/dev/null | tail -1))"
echo "CI pandoc:    $ci_version ($ci_source)"
[ -n "$image_note" ] && echo "! $image_note"

minor() { echo "$1" | cut -d. -f1,2; }

if [ "$local_version" = "$ci_version" ]; then
  echo "✔ versions match, a local render writes the same HTML as CI"
  exit 0
fi

if [ "$(minor "$local_version")" = "$(minor "$ci_version")" ]; then
  echo "✔ only the patch level differs, which does not change the rendered HTML"
  exit 0
fi

echo "✖ pandoc version mismatch - a local render will rewrite docs/ with whitespace-only changes"
if [ "$(echo "$local_version" | cut -d. -f1)" != "$(echo "$ci_version" | cut -d. -f1)" ]; then
  echo "  major difference: raw-HTML inlines are wrapped by pandoc 3 and not by pandoc 2"
else
  echo "  minor difference: pandoc's built-in <style> block differs, so every page changes"
fi
echo "  render in the CI image instead ('make image_render'), or install a matching"
echo "  pandoc, see the \"Pandoc version\" section of the README"
exit 1
