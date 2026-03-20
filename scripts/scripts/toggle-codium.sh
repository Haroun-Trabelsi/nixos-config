#!/usr/bin/env bash
# Toggle Codium (VSCodium): launch if not running, focus if running, go back if focused

ACTIVE_CLASS=$(hyprctl activewindow -j | jq -r '.class')

if [ "$ACTIVE_CLASS" = "codium" ]; then
    # Already focused - go back to previous workspace
    hyprctl dispatch workspace previous
elif hyprctl clients -j | jq -e '.[] | select(.class == "codium")' > /dev/null 2>&1; then
    # Running but not focused - focus it
    hyprctl dispatch focuswindow class:codium
else
    # Not running - launch (window rule sends to workspace 8)
    codium &
fi
