#!/usr/bin/env bash
# Hyprland has `movetoworkspace, empty`; sway has no equivalent, so both go
# through the same computed-empty-workspace path for consistent behaviour.
set -euo pipefail
n=$(wm empty-workspace)
if [ "$(wm which)" = sway ]; then
  swaymsg "move container to workspace number $n"
else
  hyprctl dispatch movetoworkspace "$n"
fi
wm workspace "$n"
