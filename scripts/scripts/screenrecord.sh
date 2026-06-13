#!/usr/bin/env bash

dir="$HOME/Videos/Recordings"
mkdir -p "$dir"

pidfile="/tmp/wf-recorder.pid"

if [[ -f "$pidfile" ]] && kill -0 "$(cat "$pidfile")" 2>/dev/null; then
    pid=$(cat "$pidfile")
    file=$(cat "/tmp/wf-recorder.file" 2>/dev/null)
    kill -SIGINT "$pid"
    wait "$pid" 2>/dev/null
    rm -f "$pidfile" /tmp/wf-recorder.file
    notify-send "Screen recording stopped" "${file:-saved}" -i media-record
    [[ -n "$file" ]] && wl-copy < "$file" 2>/dev/null || true
    exit 0
fi

time=$(date +'%Y_%m_%d_at_%Hh%Mm%Ss')
file="${dir}/Recording_${time}.mp4"

output=$(hyprctl -j monitors | jq -r '.[] | select(.focused) | .name')

wf-recorder -o "$output" -f "$file" &
echo $! > "$pidfile"
echo "$file" > /tmp/wf-recorder.file

notify-send "Screen recording started" "$output → $(basename "$file")" -i media-record
