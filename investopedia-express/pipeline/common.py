"""Shared helpers for the Investopedia Express data pipeline."""
from __future__ import annotations

import json
import pathlib
import re
import html as htmllib

ROOT = pathlib.Path(__file__).resolve().parent.parent  # investopedia-express/
DATA = ROOT / "data"
RAW = ROOT / "data-raw"
LOGOS = ROOT / "logos"
PIPE = ROOT / "pipeline"

UA = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"


def ensure_dirs() -> None:
    for d in (DATA, RAW, LOGOS):
        d.mkdir(parents=True, exist_ok=True)


def read_json(path: pathlib.Path, default=None):
    if not path.exists():
        return default
    with open(path, "r", encoding="utf-8") as fh:
        return json.load(fh)


def write_json(path: pathlib.Path, obj, compact: bool = False) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8") as fh:
        if compact:
            json.dump(obj, fh, ensure_ascii=False, separators=(",", ":"))
        else:
            json.dump(obj, fh, ensure_ascii=False, indent=1)
        fh.write("\n")


def strip_html(s: str | None) -> str:
    if not s:
        return ""
    s = re.sub(r"(?i)<br\s*/?>", "\n", s)
    s = re.sub(r"(?i)</(p|div|li|h\d)>", "\n", s)
    s = re.sub(r"<[^>]+>", "", s)
    s = htmllib.unescape(s)
    s = s.replace("\xa0", " ")
    s = re.sub(r"[ \t]+", " ", s)
    s = re.sub(r"\n\s*\n+", "\n", s)
    return s.strip()


def slugify(s: str, maxlen: int = 60) -> str:
    s = re.sub(r"[^a-zA-Z0-9]+", "-", s.lower()).strip("-")
    return s[:maxlen].rstrip("-") or "episode"
