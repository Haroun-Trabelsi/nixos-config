#!/usr/bin/env bash

# based on https://github.com/ash-17/omarchy-external-monitor/tree/d06a323e7fb39d73be3955b94305830bfdc4a74a

restart-apps() {
    sleep 1

    # restart shell (handles wallpaper too)
    pkill noctalia-shell 2> /dev/null
    noctalia-shell &

    # restart swayosd (crashes on monitor change)
    pkill .swayosd-server 2> /dev/null
    swayosd-server &
}

# listen for hyprland events
socat -U - UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" |
    while read -r line; do
        # react on external monitor plug/unplug
        if echo "$line" | grep -qE "monitor(added|removed)>>(HDMI|DP)"; then
            sleep 1

            # keep laptop screen on and mirror any external monitor onto it
            hyprctl keyword monitor "eDP-1,preferred,auto,1"
            while read -r ext; do
                hyprctl keyword monitor "${ext},preferred,auto,1,mirror,eDP-1"
            done < <(hyprctl monitors -j | jq -r '.[] | select(.name != "eDP-1") | .name')

            # restart some apps after monitor change
            restart-apps
        fi
    done
