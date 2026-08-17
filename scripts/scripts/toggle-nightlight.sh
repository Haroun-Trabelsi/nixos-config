#!/usr/bin/env bash
# Replaces `noctalia-shell ipc call nightLight toggle`.
if pgrep -x wlsunset >/dev/null; then
    pkill -x wlsunset && notify-send "Night light" "off"
else
    wlsunset -l 36.8 -L 10.2 & notify-send "Night light" "on"
fi
