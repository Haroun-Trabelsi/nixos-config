#!/usr/bin/env bash

SERVICE="noctalia-shell"

if pgrep -x "$SERVICE" > /dev/null; then
    pkill -9 noctalia-shell
else
    runbg noctalia-shell
fi
