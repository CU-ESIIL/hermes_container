#!/usr/bin/env python3
"""Capture a webpage screenshot into /data/outputs/figures."""

from pathlib import Path
import sys

from playwright.sync_api import sync_playwright


url = sys.argv[1] if len(sys.argv) > 1 else "http://127.0.0.1:18789"
output = Path(sys.argv[2]) if len(sys.argv) > 2 else Path("/data/outputs/figures/webpage.png")
output.parent.mkdir(parents=True, exist_ok=True)

with sync_playwright() as p:
    browser = p.chromium.launch()
    page = browser.new_page(viewport={"width": 1440, "height": 1000})
    page.goto(url, wait_until="networkidle")
    page.screenshot(path=str(output), full_page=True)
    browser.close()

print(f"Wrote {output}")
