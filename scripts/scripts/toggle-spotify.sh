#!/usr/bin/env bash
# Toggle Spotify: launch if not running, focus if running, go back if focused

ACTIVE_CLASS=$(hyprctl activewindow -j | jq -r '.class')

if [ "$ACTIVE_CLASS" = "Spotify" ] || [ "$ACTIVE_CLASS" = "spotify" ]; then
    # Already focused - go back to previous workspace
    hyprctl dispatch workspace previous
elif hyprctl clients -j | jq -e '.[] | select(.class == "Spotify" or .class == "spotify")' > /dev/null 2>&1; then
    # Running but not focused - switch to workspace 9 and focus it
    hyprctl dispatch workspace 9
    hyprctl dispatch focuswindow class:Spotify || hyprctl dispatch focuswindow class:spotify
else
    # Not running - launch on workspace 9 and switch to it
    hyprctl dispatch exec '[workspace 9 silent]' spotify
    sleep 1
    hyprctl dispatch workspace 9
fi
