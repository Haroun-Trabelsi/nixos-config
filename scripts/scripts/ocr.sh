#!/usr/bin/env bash
# Select a region, OCR it, put the text on the clipboard. grim+slurp so it works
# on both compositors.
set -euo pipefail
tmp=$(mktemp --suffix=.png)
trap 'rm -f "$tmp"' EXIT
region=$(slurp) || exit 1
grim -g "$region" "$tmp"
tesseract "$tmp" - 2>/dev/null | wl-copy
notify-send "OCR" "Text copied to clipboard"
