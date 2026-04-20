{ host, pkgs, ... }:
{
  wayland.windowManager.hyprland.settings.env = [
    "QYLOCK_THEMES,${pkgs.qylock}/share/qylock/themes"
  ];

  wayland.windowManager.hyprland.settings.exec-once = [
    # Lock screen FIRST so it paints before wallpaper/bar flash up
    "qylock"

    # "hash dbus-update-activation-environment 2>/dev/null"
    "dbus-update-activation-environment --all --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
    "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"

    # Wait for qylock to be running before launching visible desktop surfaces
    # Animated video wallpaper via mpvpaper (restores last choice, defaults to Hollow Knight)
    "bash -c 'for i in {1..50}; do pgrep -x qylock >/dev/null && break; sleep 0.05; done; qywall restore'"

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
    "[workspace 1 silent] zen-beta"
    "[workspace 2 silent] ghostty"
  ];
}
