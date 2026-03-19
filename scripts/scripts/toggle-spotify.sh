#!/usr/bin/env bash
# Toggle Spotify: launch if not running, focus if running, go back if focused

ACTIVE_CLASS=$(hyprctl activewindow -j | jq -r '.class')

if [ "$ACTIVE_CLASS" = "Spotify" ] || [ "$ACTIVE_CLASS" = "spotify" ]; then
    # Already focused - go back to previous workspace
    hyprctl dispatch workspace previous
elif hyprctl clients -j | jq -e '.[] | select(.class == "Spotify" or .class == "spotify")' > /dev/null 2>&1; then
    # Running but not focused - focus it
    hyprctl dispatch focuswindow class:Spotify || hyprctl dispatch focuswindow class:spotify
else
    # Not running - launch (window rule sends to workspace 9)
    spotify &
fi
