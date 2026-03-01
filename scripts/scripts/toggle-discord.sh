#!/usr/bin/env bash
# Toggle Discord (vesktop): launch if not running, focus if running, go back if focused

ACTIVE_CLASS=$(hyprctl activewindow -j | jq -r '.class')

if [ "$ACTIVE_CLASS" = "vesktop" ]; then
    # Already focused - go back to previous workspace
    hyprctl dispatch workspace previous
elif hyprctl clients -j | jq -e '.[] | select(.class == "vesktop")' > /dev/null 2>&1; then
    # Running but not focused - focus it
    hyprctl dispatch focuswindow class:vesktop
else
    # Not running - launch on workspace 10
    vesktop --enable-features=UseOzonePlatform --ozone-platform=wayland &
fi
