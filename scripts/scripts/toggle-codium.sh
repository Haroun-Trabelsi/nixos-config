#!/usr/bin/env bash
# Toggle Codium on workspace 8: launch if not running, focus if running, go back if focused

ACTIVE_WINDOW=$(hyprctl activewindow -j)
ACTIVE_CLASS=$(echo "$ACTIVE_WINDOW" | jq -r '.class')
ACTIVE_WS=$(echo "$ACTIVE_WINDOW" | jq -r '.workspace.id')

# Find codium window on workspace 8
WS8_CODIUM=$(hyprctl clients -j | jq -e '[.[] | select(.class == "codium" and .workspace.id == 8)] | first // empty' 2>/dev/null)

if [ "$ACTIVE_CLASS" = "codium" ] && [ "$ACTIVE_WS" = "8" ]; then
    # Already focused on workspace 8 codium - go back
    hyprctl dispatch workspace previous
elif [ -n "$WS8_CODIUM" ]; then
    # Codium exists on workspace 8 - focus it
    ADDR=$(echo "$WS8_CODIUM" | jq -r '.address')
    hyprctl dispatch focuswindow "address:$ADDR"
else
    # No codium on workspace 8 - launch (window rule sends to workspace 8)
    codium &
fi
