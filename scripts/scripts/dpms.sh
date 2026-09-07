#!/usr/bin/env bash
# Turn displays off/on, whichever compositor is running.
# Used by the shared swayidle ladder, which now covers both machines.
case "${1:-}" in
  off|on) ;;
  *) echo "usage: dpms on|off" >&2; exit 2 ;;
esac
if [ -n "${SWAYSOCK:-}" ]; then
  exec swaymsg "output * dpms $1"
elif [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
  exec hyprctl dispatch dpms "$1"
else
  echo "dpms: no supported compositor detected" >&2; exit 1
fi
