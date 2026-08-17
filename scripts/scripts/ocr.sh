#!/usr/bin/env bash
# Select a region, OCR it, put the text on the clipboard.
set -euo pipefail
tmp=$(mktemp --suffix=.png)
trap 'rm -f "$tmp"' EXIT
grimshot save area "$tmp"
tesseract "$tmp" - 2>/dev/null | wl-copy
notify-send "OCR" "Text copied to clipboard"
