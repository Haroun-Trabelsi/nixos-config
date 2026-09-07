#!/usr/bin/env bash
# Generic show/hide/launch toggle, compositor-agnostic via `wm`.
#
#   toggle-app <ident> <launch command...>
#
# <ident> is the window's app_id (Wayland) or class (Xwayland) — `wm` checks
# both on sway and uses class on Hyprland. Find the real value with:
#   swaymsg -t get_tree | jq '..|select(.pid?)|{app_id,class,name}'   (sway)
#   hyprctl clients -j  | jq '.[].class'                              (hyprland)
#
# Behaviour: focused -> go back; running -> focus; otherwise -> launch.
set -uo pipefail
ident=$1; shift
[ "$(wm focused)" = "$ident" ] && { wm back; exit 0; }
wm running "$ident" && { wm focus "$ident"; exit 0; }
exec "$@"
