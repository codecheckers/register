#!/usr/bin/env bash
# Render pages of the rendered register in docs/ at several viewport widths
# with headless Chrome. Reads what is in docs/ - it never renders, so run
# `make render` (or `make cert CERT_ID=...`) first if the pages are stale.
#
#   test/screenshot.sh [-o OUTDIR] [-w WIDTHxHEIGHT[,...]] [PATH ...]
#
#   -o OUTDIR     where to write the PNGs (default: a fresh dir under /tmp)
#   -w LIST       comma-separated viewports (default: the three below)
#   PATH ...      register paths to shoot, e.g. / /certs/2026-023/
#                 (default: /)
#
# Prints the written file paths, one per line.
set -euo pipefail

cd "$(dirname "$0")/.."

# 393x851 = Fairphone FP4 and most current Android phones in CSS pixels
# 768x1024 = tablet / Bootstrap md
# 1280x900 = desktop
VIEWPORTS="393x851,768x1024,1280x900"
OUTDIR=""

while getopts "o:w:" opt; do
  case "$opt" in
    o) OUTDIR="$OPTARG" ;;
    w) VIEWPORTS="$OPTARG" ;;
    *) exit 2 ;;
  esac
done
shift $((OPTIND - 1))

PATHS=("$@")
[ ${#PATHS[@]} -eq 0 ] && PATHS=("/")

[ -d docs ] || { echo 'no docs/, run "make render" first' >&2; exit 1; }
[ -n "$OUTDIR" ] || OUTDIR="$(mktemp -d /tmp/register-shots-XXXX)"
mkdir -p "$OUTDIR"

CHROME="$(command -v google-chrome || command -v chromium || command -v chromium-browser)"

PORT=$(python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1",0)); print(s.getsockname()[1]); s.close()')
python3 -m http.server "$PORT" --bind 127.0.0.1 --directory docs >/dev/null 2>&1 &
SERVER=$!
trap 'kill $SERVER 2>/dev/null' EXIT
sleep 1

for p in "${PATHS[@]}"; do
  slug=$(echo "$p" | sed 's#^/##; s#/$##; s#/#-#g'); slug=${slug:-index}
  IFS=, read -ra sizes <<< "$VIEWPORTS"
  for size in "${sizes[@]}"; do
    out="$OUTDIR/$slug-$size.png"
    "$CHROME" --headless --disable-gpu --hide-scrollbars --no-sandbox \
      --window-size="${size/x/,}" --virtual-time-budget=8000 \
      --screenshot="$out" "http://127.0.0.1:$PORT$p" >/dev/null 2>&1
    echo "$out"
  done
done
