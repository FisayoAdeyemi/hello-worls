"""Probe where transcripts for the show might live. Saves raw HTML for
inspection plus a small JSON report. Only run on demand (mode=probe)."""
from __future__ import annotations

import json
import re
import sys

import requests

from common import RAW, DATA, UA, ensure_dirs, read_json, write_json, strip_html


def fetch(url: str, timeout: int = 60):
    try:
        r = requests.get(url, timeout=timeout, headers={"User-Agent": UA, "Accept-Language": "en-US,en;q=0.9"})
        return r.status_code, r.text, r.url
    except Exception as exc:  # noqa: BLE001
        return None, str(exc), url


def summarise(url: str, status, body: str, final_url: str):
    low = body.lower() if body else ""
    idx = low.find("transcript")
    return {
        "url": url,
        "final_url": final_url,
        "status": status,
        "length": len(body or ""),
        "mentions_transcript": low.count("transcript"),
        "transcript_context": body[max(0, idx - 200): idx + 400] if idx >= 0 else None,
        "text_length": len(strip_html(body)) if body else 0,
    }


def main() -> int:
    ensure_dirs()
    out = RAW / "probe"
    out.mkdir(parents=True, exist_ok=True)
    eps = (read_json(DATA / "episodes.json") or {}).get("episodes", [])
    urls = [
        "https://www.investopedia.com/the-investopedia-express-podcast-5220453",
        "https://itunes.apple.com/lookup?id=1529322197&entity=podcastEpisode&limit=5",
        "https://podscripts.co/podcasts/the-investopedia-express-with-caleb-silver",
        "https://www.podscribe.com/",
    ]
    # A few episode links spread across the run of the show
    picks = []
    if eps:
        for i in {0, 1, len(eps) // 2, len(eps) - 2, len(eps) - 1}:
            if 0 <= i < len(eps) and eps[i].get("link"):
                picks.append(eps[i]["link"])
    urls.extend(picks)
    report = []
    for n, u in enumerate(urls):
        status, body, final = fetch(u)
        fname = out / f"page{n:02d}.html"
        fname.write_text(body or "", encoding="utf-8")
        s = summarise(u, status, body or "", final)
        s["file"] = str(fname.relative_to(RAW.parent))
        report.append(s)
        print(json.dumps({k: s[k] for k in ("url", "status", "length", "mentions_transcript", "text_length")}))
    write_json(RAW / "probe_report.json", report)
    return 0


if __name__ == "__main__":
    sys.exit(main())
