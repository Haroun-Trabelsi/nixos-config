#!/usr/bin/env bash
# Thin abstraction over the running compositor, so one set of scripts and one
# set of keybinds work on both machines: sway on the laptop, Hyprland on the
# desktop. Detects via SWAYSOCK / HYPRLAND_INSTANCE_SIGNATURE.
#
# Subcommands:
#   wm which                      -> "sway" | "hyprland"
#   wm focused <class|app_id>     -> identifier of the focused window
#   wm running <ident>            -> exit 0 if a window with that identifier exists
#   wm focus <ident>              -> focus it
#   wm back                       -> previous workspace
#   wm workspace <n>              -> switch to workspace n
#   wm focused-output             -> name of the focused output
#   wm float-center <w> <h>       -> float the focused window and centre it
#   wm empty-workspace            -> lowest-numbered unused workspace
set -uo pipefail

WM=""
if   [ -n "${SWAYSOCK:-}" ];                    then WM=sway
elif [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then WM=hyprland
fi
[ -z "$WM" ] && { echo "wm: no supported compositor detected" >&2; exit 1; }

cmd=${1:-}; shift 2>/dev/null || true

case "$cmd" in
  which) echo "$WM" ;;

  focused)
    if [ "$WM" = sway ]; then
      # sway: Wayland clients carry app_id, Xwayland ones carry class
      swaymsg -t get_tree | jq -r 'recurse(.nodes[]?,.floating_nodes[]?)
        | select(.focused==true) | (.app_id // .window_properties.class // empty)'
    else
      hyprctl activewindow -j | jq -r '.class // empty'
    fi ;;

  running)
    if [ "$WM" = sway ]; then
      swaymsg -t get_tree | jq -e --arg i "${1:-}" 'recurse(.nodes[]?,.floating_nodes[]?)
        | select(.pid? and ((.app_id // .window_properties.class // "") == $i))' >/dev/null
    else
      hyprctl clients -j | jq -e --arg i "${1:-}" '.[] | select(.class == $i)' >/dev/null
    fi ;;

  focus)
    if [ "$WM" = sway ]; then
      swaymsg "[app_id=\"^${1}$\"] focus" >/dev/null 2>&1 \
        || swaymsg "[class=\"^${1}$\"] focus" >/dev/null
    else
      hyprctl dispatch focuswindow "class:${1}" >/dev/null
    fi ;;

  back)
    [ "$WM" = sway ] && swaymsg workspace back_and_forth >/dev/null \
                     || hyprctl dispatch workspace previous >/dev/null ;;

  workspace)
    [ "$WM" = sway ] && swaymsg workspace number "${1}" >/dev/null \
                     || hyprctl dispatch workspace "${1}" >/dev/null ;;

  focused-output)
    if [ "$WM" = sway ]; then
      swaymsg -t get_outputs -r | jq -r '.[] | select(.focused) | .name'
    else
      hyprctl monitors -j | jq -r '.[] | select(.focused) | .name'
    fi ;;

  float-center)
    w=${1:-1111}; h=${2:-700}
    if [ "$WM" = sway ]; then
      swaymsg floating toggle >/dev/null
      swaymsg resize set "$w" "$h" >/dev/null
      swaymsg move position center >/dev/null
    else
      hyprctl dispatch togglefloating >/dev/null
      hyprctl dispatch resizeactive exact "$w" "$h" >/dev/null
      hyprctl dispatch centerwindow >/dev/null
    fi ;;

  empty-workspace)
    if [ "$WM" = sway ]; then
      used=$(swaymsg -t get_workspaces | jq '[.[].num]')
    else
      used=$(hyprctl workspaces -j | jq '[.[].id]')
    fi
    n=1
    while [ "$(jq --argjson n "$n" 'index($n) != null' <<<"$used")" = "true" ]; do n=$((n+1)); done
    echo "$n" ;;

  *) echo "wm: unknown subcommand '${cmd}'" >&2; exit 2 ;;
esac
