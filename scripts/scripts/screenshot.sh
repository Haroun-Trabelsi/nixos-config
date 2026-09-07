#!/usr/bin/env bash
# grim + slurp directly: works on sway AND Hyprland, unlike grimshot (sway-only)
# or grimblast (Hyprland-only). One script for both machines.
set -uo pipefail
dir="$HOME/Pictures/Screenshots"
file="${dir}/Screenshot_$(date +'%Y_%m_%d_at_%Hh%Mm%Ss').png"
mkdir -p "$dir"

region=$(slurp) || exit 1   # cancelled
case "${1:---copy}" in
  --copy)   grim -g "$region" - | wl-copy && notify-send "Screenshot" "Copied to clipboard" ;;
  --save)   grim -g "$region" "$file" && notify-send "Screenshot" "Saved to $file" ;;
  --swappy) grim -g "$region" "$file" && swappy -f "$file" ;;
  *)        grim -g "$region" - | wl-copy ;;
esac
