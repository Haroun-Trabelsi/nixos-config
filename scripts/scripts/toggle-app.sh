#!/usr/bin/env bash
# Generic show/hide/launch toggle for sway.
#
#   toggle-app <criteria> <pattern> <launch command...>
#
# criteria is "app_id" (Wayland clients) or "class" (Xwayland clients) — getting
# that wrong is the usual reason a toggle silently does nothing. Check with:
#   swaymsg -t get_tree | jq '.. | select(.pid?) | {app_id, class, name}'
#
# Behaviour matches the old hyprctl versions: focused -> go back, running ->
# focus, otherwise -> launch.
set -euo pipefail

crit=$1; pat=$2; shift 2

tree=$(swaymsg -t get_tree)

focused=$(jq -r --arg c "$crit" '.. | select(.focused? == true) | .[$c] // empty' <<<"$tree")
if [[ "$focused" == "$pat" ]]; then
    swaymsg workspace back_and_forth
    exit 0
fi

if jq -e --arg c "$crit" --arg p "$pat" '.. | select(.pid? and (.[$c] // "") == $p)' <<<"$tree" >/dev/null; then
    swaymsg "[$crit=\"^${pat}$\"] focus"
    exit 0
fi

exec "$@"
