#!/usr/bin/env bash
# Toggle a second Codium instance (on workspace 7): launch if not running, focus if running, go back if focused

ACTIVE_WINDOW=$(hyprctl activewindow -j)
ACTIVE_CLASS=$(echo "$ACTIVE_WINDOW" | jq -r '.class')
ACTIVE_WS=$(echo "$ACTIVE_WINDOW" | jq -r '.workspace.id')

# Find codium window on workspace 7
ALT_CODIUM=$(hyprctl clients -j | jq -e '[.[] | select(.class == "codium" and .workspace.id == 7)] | first // empty' 2>/dev/null)

if [ "$ACTIVE_CLASS" = "codium" ] && [ "$ACTIVE_WS" = "7" ]; then
    # Already focused on the alt codium - go back
    hyprctl dispatch workspace previous
elif [ -n "$ALT_CODIUM" ]; then
    # Alt codium exists - focus it
    ADDR=$(echo "$ALT_CODIUM" | jq -r '.address')
    hyprctl dispatch focuswindow "address:$ADDR"
else
    # No alt codium - launch a new instance on workspace 7
    hyprctl dispatch exec '[workspace 7 silent]' codium --new-window

fi
