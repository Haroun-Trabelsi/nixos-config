#!/usr/bin/env bash
# fuzzel dmenu replacing the rofi version (rofi is no longer installed).
set -euo pipefail

chosen=$(printf '%s\n' \
    "󰌾  Lock" \
    "󰤄  Suspend" \
    "󰜉  Reboot" \
    "󰐥  Shutdown" \
    "󰗽  Exit sway" \
    | fuzzel --dmenu --lines=5 --prompt='  ')

case "$chosen" in
    *Lock)     swaylock -f ;;
    *Suspend)  systemctl suspend ;;   # swayidle's before-sleep hook locks
    *Reboot)   systemctl reboot ;;
    *Shutdown) systemctl poweroff ;;
    *"Exit sway") swaymsg exit ;;
esac
