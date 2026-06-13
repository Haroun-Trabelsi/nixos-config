{ host, ... }:
{
  wayland.windowManager.hyprland.settings.exec-once = [
    # Lock screen FIRST so it paints before wallpaper/bar flash up
    "qylock"

    # "hash dbus-update-activation-environment 2>/dev/null"
    "dbus-update-activation-environment --all --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
    "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"

    "nm-applet --indicator &"
    "poweralertd &"
    "wl-clip-persist --clipboard both &"
    "wl-paste --watch cliphist store &"
    "swaync &"
    "udiskie --automount --notify --smart-tray &"
    "hyprctl setcursor Nordzy-catppuccin-macchiato-dark 24 &"
    "bash -c 'for i in {1..50}; do pgrep -x qylock >/dev/null && break; sleep 0.05; done; noctalia-shell &'"

    # start monitor watcher on real hardware (not VM)
    "${if (host != "vm") then "monitor-watcher &" else ""}"

    # enable keep awake on desktop (no idle/sleep)
    # "${if (host == "desktop") then "caelestia shell idleInhibitor enable" else ""}"
    "${if (host == "desktop") then "sleep 5 && noctalia-shell ipc call idleInhibitor enable" else ""}"

    # enable noctalia performance mode by default (wallpaper stays on via settings)
    "sleep 5 && noctalia-shell ipc call powerProfile enableNoctaliaPerformance"

    "ghostty --gtk-single-instance=true --quit-after-last-window-closed=false --initial-window=false"
    "[workspace 2 silent] ghostty"

    # Wallpaper Engine wallpaper on all monitors (muted)
    "bash -c 'for i in {1..50}; do hyprctl monitors -j | jq -e \".[0].name\" >/dev/null 2>&1 && break; sleep 0.1; done; args=\"\"; for out in $(hyprctl monitors -j | jq -r \".[].name\"); do args=\"$args --screen-root $out --bg 2411270069\"; done; exec linux-wallpaperengine --silent --no-fullscreen-pause --fps 60 $args >/dev/null 2>&1'"
  ];
}
