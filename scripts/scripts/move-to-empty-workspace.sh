#!/usr/bin/env bash
# Replaces Hyprland's `movetoworkspace, empty`, which sway has no equivalent for.
set -euo pipefail
used=$(swaymsg -t get_workspaces | jq '[.[].num]')
n=1
while [[ $(jq --argjson n "$n" 'index($n) != null' <<<"$used") == "true" ]]; do
    n=$((n + 1))
done
swaymsg "move container to workspace number $n"
swaymsg "workspace number $n"
