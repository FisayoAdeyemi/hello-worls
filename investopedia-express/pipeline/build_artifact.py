"""Bundle the app into one self-contained HTML file (data, prices and logos inlined).

Used for publishing a copy as a claude.ai Artifact, whose sandbox blocks all
external requests. Output: dist/express-tracker.html
"""
from __future__ import annotations

import base64
import json
import pathlib
import re
import sys

from common import ROOT, DATA, LOGOS, read_json


def data_uri(path: pathlib.Path) -> str | None:
    if not path.exists():
        return None
    return "data:image/png;base64," + base64.b64encode(path.read_bytes()).decode("ascii")


def main() -> int:
    html = (ROOT / "index.html").read_text(encoding="utf-8")
    app = read_json(DATA / "app.json")
    prices = {}
    for c in app["companies"]:
        if c.get("priceFile"):
            j = read_json(ROOT / c["priceFile"])
            if j:
                j["c"] = [round(x, 2) for x in j["c"]]
                j["a"] = [round(x, 2) for x in j["a"]]
                prices[c["t"]] = j
        for key in ("logo", "logoMono"):
            if c.get(key):
                c[key] = data_uri(ROOT / c[key])
    for b, rec in (app.get("benchmarks") or {}).items():
        j = read_json(ROOT / rec["priceFile"])
        if j:
            j["c"] = [round(x, 2) for x in j["c"]]
            j["a"] = [round(x, 2) for x in j["a"]]
            prices[b] = j

    d3 = (ROOT / "vendor" / "d3.min.js").read_text(encoding="utf-8")
    inline = (
        "<script>window.__ARTIFACT__=true;window.__APP__=" + json.dumps(app, separators=(",", ":")).replace("</", "<\\/")
        + ";window.__PRICES__=" + json.dumps(prices, separators=(",", ":")).replace("</", "<\\/") + ";</script>\n"
        "<script>" + d3.replace("</script>", "<\\/script>") + "</script>"
    )
    html = html.replace('<script src="vendor/d3.min.js"></script>', inline)
    # The artifact host wraps the page in its own document skeleton.
    html = re.sub(r"^\s*<!doctype html>\s*<html[^>]*>\s*<head>\s*", "", html, flags=re.I)
    html = re.sub(r"\s*</head>\s*<body>\s*", "\n", html, count=1, flags=re.I)
    html = re.sub(r"\s*</body>\s*</html>\s*$", "\n", html, flags=re.I)
    html = re.sub(r'<meta charset="utf-8">\s*<meta name="viewport"[^>]*>\s*', "", html)
    out = ROOT / "dist"
    out.mkdir(exist_ok=True)
    (out / "express-tracker.html").write_text(html, encoding="utf-8")
    print(f"dist/express-tracker.html: {len(html)/1e6:.2f} MB, {len(prices)} price series, {len(app['companies'])} companies")
    return 0


if __name__ == "__main__":
    sys.exit(main())
