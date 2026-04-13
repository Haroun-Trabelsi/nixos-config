#!/usr/bin/env bash
# Toggle a second VSCode instance (on workspace 7): launch if not running, focus if running, go back if focused

ACTIVE_WINDOW=$(hyprctl activewindow -j)
ACTIVE_CLASS=$(echo "$ACTIVE_WINDOW" | jq -r '.class')
ACTIVE_WS=$(echo "$ACTIVE_WINDOW" | jq -r '.workspace.id')

# Find code window on workspace 7
ALT_CODE=$(hyprctl clients -j | jq -e '[.[] | select(.class == "code" and .workspace.id == 7)] | first // empty' 2>/dev/null)

if [ "$ACTIVE_CLASS" = "code" ] && [ "$ACTIVE_WS" = "7" ]; then
    # Already focused on the alt code - go back
    hyprctl dispatch workspace previous
elif [ -n "$ALT_CODE" ]; then
    # Alt code exists - focus it
    ADDR=$(echo "$ALT_CODE" | jq -r '.address')
    hyprctl dispatch focuswindow "address:$ADDR"
else
    # No alt code - launch a new instance on workspace 7
    hyprctl dispatch exec '[workspace 7 silent]' code --new-window

fi
