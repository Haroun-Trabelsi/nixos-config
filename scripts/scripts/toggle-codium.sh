#!/usr/bin/env bash
# Toggle VSCode on workspace 8: launch if not running, focus if running, go back if focused

ACTIVE_WINDOW=$(hyprctl activewindow -j)
ACTIVE_CLASS=$(echo "$ACTIVE_WINDOW" | jq -r '.class')
ACTIVE_WS=$(echo "$ACTIVE_WINDOW" | jq -r '.workspace.id')

# Find code window on workspace 8
WS8_CODE=$(hyprctl clients -j | jq -e '[.[] | select(.class == "code" and .workspace.id == 8)] | first // empty' 2>/dev/null)

if [ "$ACTIVE_CLASS" = "code" ] && [ "$ACTIVE_WS" = "8" ]; then
    # Already focused on workspace 8 code - go back
    hyprctl dispatch workspace previous
elif [ -n "$WS8_CODE" ]; then
    # Code exists on workspace 8 - focus it
    ADDR=$(echo "$WS8_CODE" | jq -r '.address')
    hyprctl dispatch focuswindow "address:$ADDR"
else
    # No code on workspace 8 - launch (window rule sends to workspace 8)
    code &
fi
