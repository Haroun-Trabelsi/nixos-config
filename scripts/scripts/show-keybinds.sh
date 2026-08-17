#!/usr/bin/env bash
# Reads the home-manager-generated sway config rather than hyprland.conf.
set -euo pipefail
cfg="$HOME/.config/sway/config"
{ grep -E '^\s*bind(sym|code)' "$cfg" \
    | sed -E 's/^\s*bind(sym|code)\s+(--[a-z-]+\s+)*//' \
    | sort; } | fuzzel --dmenu --lines=25 --prompt='  ' >/dev/null
