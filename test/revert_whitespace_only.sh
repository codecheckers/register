#!/usr/bin/env bash
# Restore every modified text file whose change is whitespace only, so a render
# commits just the files whose content changed. A pandoc update re-wraps
# raw-HTML lines and re-indents across all of docs/ (see the "Pandoc version"
# section of the README), which would otherwise bury the real changes in a
# commit of hundreds of files.
#
#   test/revert_whitespace_only.sh [PATH]
#
#   PATH    the part of the working tree to look at (default: docs)
#
# A change counts as whitespace only when the two versions are equal after
# every run of whitespace, line breaks included, is squeezed to one space -
# so a line that is merely wrapped differently is restored, while whitespace
# appearing or disappearing between two words is kept. Binary, new and deleted
# files are never touched. Files with a real change keep their whitespace
# changes too, so docs/ converges on the current pandoc page by page.
set -euo pipefail

cd "$(dirname "$0")/.."

TARGET="${1:-docs}"

squeeze() { tr -s '[:space:]' ' '; }

restored=0
kept=0
while IFS= read -r -d '' file; do
  if ! grep -Iq . "$file"; then
    kept=$((kept + 1))
    continue
  fi
  if [ "$(git show "HEAD:$file" | squeeze)" = "$(squeeze < "$file")" ]; then
    git checkout -q -- "$file"
    restored=$((restored + 1))
  else
    kept=$((kept + 1))
  fi
done < <(git diff -z --name-only --diff-filter=M -- "$TARGET")

echo "restored $restored files with whitespace-only changes, kept $kept changed files in $TARGET"
