#!/usr/bin/env python3
"""Report pages of docs/ that scroll sideways at a given viewport width.

    test/overflow.py [--width 393] [PATH ...]

A page whose document is wider than the viewport drags the navigation and
footer out with it and cuts off content with no visible way to reach it - the
mobile failure mode the register's wide tables used to have. Everything a
table cannot fit must scroll inside its own container instead.

Serves docs/ locally, injects a measuring script into each HTML response and
reads the numbers back out of headless Chrome's --dump-dom. Exits non-zero if
any page overflows.
"""

import argparse
import functools
import http.server
import re
import subprocess
import shutil
import sys
import threading

PROBE = (
    '<script>document.title="PROBE:"'
    "+document.documentElement.scrollWidth+':'+document.documentElement.clientWidth;</script>"
)

DEFAULT_PATHS = [
    "/",
    "/works/",
    "/persons/",
    "/venues/",
    "/organisations/",
    "/statistics/",
    "/404.html",
]


class Handler(http.server.SimpleHTTPRequestHandler):
    def send_head(self):  # inject the probe into HTML responses
        import os

        path = self.translate_path(self.path)
        if os.path.isdir(path):
            path = os.path.join(path, "index.html")
        if not path.endswith(".html"):
            return super().send_head()
        try:
            body = open(path, "rb").read() + PROBE.encode()
        except OSError:
            return super().send_head()
        self.send_response(200)
        self.send_header("Content-Type", "text/html")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        import io

        return io.BytesIO(body)

    def log_message(self, *args):
        pass


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--width", type=int, default=393, help="viewport width in CSS px")
    ap.add_argument("paths", nargs="*", default=DEFAULT_PATHS)
    args = ap.parse_args()

    chrome = next(
        (c for c in ("google-chrome", "chromium", "chromium-browser") if shutil.which(c)),
        None,
    )
    if not chrome:
        sys.exit("no chrome/chromium found")

    server = http.server.ThreadingHTTPServer(
        ("127.0.0.1", 0),
        functools.partial(Handler, directory="docs"),
    )
    threading.Thread(target=server.serve_forever, daemon=True).start()
    port = server.server_address[1]

    failed = False
    for path in args.paths:
        dom = subprocess.run(
            [
                chrome, "--headless", "--disable-gpu", "--no-sandbox",
                f"--window-size={args.width},851", "--virtual-time-budget=8000",
                "--dump-dom", f"http://127.0.0.1:{port}{path}",
            ],
            capture_output=True, text=True,
        ).stdout
        match = re.search(r"PROBE:(\d+):(\d+)", dom)
        if not match:
            print(f"?? {path}: could not measure")
            failed = True
            continue
        scroll, client = int(match.group(1)), int(match.group(2))
        # Chrome's --dump-dom ignores --window-size, so compare the numbers the
        # page itself reports rather than the requested width.
        ok = scroll <= client
        failed = failed or not ok
        print(f"{'ok' if ok else 'OVERFLOW'} {path}: document {scroll}px in {client}px viewport")

    server.shutdown()
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
