#!/usr/bin/env bash
# Win+C: bring up a work terminal on workspace 8 and focus it.
# If a kitty window is already on WS8, switch there and focus it; otherwise open
# one first. This avoids stacking a fresh terminal on every press.
# If already on WS8, toggle back to the previous workspace instead.

WS=8

active=$(swaymsg -t get_workspaces | jq -r '.[] | select(.focused) | .num')
if [ "$active" = "$WS" ]; then
    swaymsg workspace back_and_forth
    exit 0
fi

# sway has no "exec on workspace N" — switch first, then launch, so the new
# window lands on WS8 by virtue of it being the focused workspace.
count=$(swaymsg -t get_tree | jq --argjson ws "$WS" \
    '[recurse(.nodes[]?) | select(.type=="workspace" and .num==$ws) | recurse(.nodes[]?,.floating_nodes[]?) | select(.app_id=="kitty")] | length')

swaymsg workspace number "$WS"
if [ "${count:-0}" -lt 1 ]; then
    swaymsg exec kitty
fi
