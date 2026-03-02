{ lib, host, ... }:
{
  wayland.windowManager.hyprland.settings.exec-once = [
    # "hash dbus-update-activation-environment 2>/dev/null"
    "dbus-update-activation-environment --all --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
    "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"

    "hyprlock"

    "nm-applet --indicator &"
    "poweralertd &"
    "wl-clip-persist --clipboard both &"
    "wl-paste --watch cliphist store &"
    "swaync &"
    "udiskie --automount --notify --smart-tray &"
    "hyprctl setcursor Bibata-Modern-Ice 24 &"
    "init-wallpaper &"

    # start monitor watcher on real hardware (not VM)
    "${if (host != "vm") then "monitor-watcher &" else ""}"

    "ghostty --gtk-single-instance=true --quit-after-last-window-closed=false --initial-window=false"
    "[workspace 1 silent] zen-beta"
    "[workspace 2 silent] ghostty"
  ];
}
