#!/usr/bin/env bash
# Report files a page render leaves behind in docs/ when it does not clean up:
# the temporary inputs of a page (temp.md, index_header.html,
# index_prefix.html, index_postfix.html, html_document.yml) and page-local
# libs/ folders. Only docs/libs is shared by all pages, every other page links
# to it (see edit_html_lib_paths() in the codecheck package).
#
#   test/stray_files.sh [DIR]
#
#   DIR    the rendered site to check (default: docs)
#
# Exits 0 when nothing is left behind, and 1 listing the stray files otherwise.
# Since codecheck requires rmarkdown 2.32 (codecheckers/codecheck#88), a render
# removes them even when a page fails, so a hit means a killed render or a
# leftover from an older one - delete the listed paths.
set -euo pipefail

cd "$(dirname "$0")/.."

DIR="${1:-docs}"
DIR="${DIR%/}"

stray="$(find "$DIR" \( -type f \( -name temp.md -o -name index_header.html \
  -o -name index_prefix.html -o -name index_postfix.html -o -name html_document.yml \) \) \
  -o \( -type d -name libs -not -path "$DIR/libs" -prune \) | sort)"

if [ -z "$stray" ]; then
  echo "✔ no temporary render files or page-local libs/ in $DIR"
  exit 0
fi

echo "✖ $(echo "$stray" | wc -l) temporary render files or page-local libs/ in $DIR:"
echo "$stray" | sed 's/^/  /'
exit 1
