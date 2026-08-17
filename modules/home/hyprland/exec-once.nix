{ ... }:
{
  wayland.windowManager.hyprland.settings.exec-once = [
    # Nothing auto-locks at login. Lock manually with Win+Escape or the power menu.

    # "hash dbus-update-activation-environment 2>/dev/null"
    "dbus-update-activation-environment --all --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
    "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"

    "nm-applet --indicator &"
    "poweralertd &"
    "wl-clip-persist --clipboard both &"
    "wl-paste --watch cliphist store &"
    "udiskie --automount --notify --smart-tray &"
    "hyprctl setcursor Nordzy-catppuccin-macchiato-dark 24 &"
    "noctalia-shell &"

    # (the old `host != "vm"` guard went away with the vm host)
    "monitor-watcher &"

    # Removed for the ~10 W power target:
    #
    #   swaync                  dead line — swaync is not installed by this flake
    #                           and noctalia already owns notifications.
    #
    #   idleInhibitor enable    pinned the session awake, so the screen never
    #                           blanked and the machine never idled. On a 36.6 Wh
    #                           laptop that is the difference between DPMS-off
    #                           saving ~1.5 W and saving nothing.
    #
    #   powerProfile enable-    asked noctalia for *performance* mode at every
    #   NoctaliaPerformance     login, fighting every governor/EPP setting.
    #
    #   linux-wallpaperengine   rendered an animated wallpaper at 60 fps on every
    #                           output with --no-fullscreen-pause. The single
    #                           largest continuous GPU cost in this config: it
    #                           held the iGPU out of RC6 (gt_cur_freq pinned at
    #                           550 MHz against an RPn of 100) and defeated panel
    #                           self-refresh entirely. Est. 3-6 W.
    #
    #   ghostty x2, thorium,    the autostart zoo. Five apps (four of them
    #   openrgb, spotify,       Electron/Chromium) launched at login whether or
    #   vesktop, twin kitty     not they were wanted, each holding memory and
    #                           waking the CPU forever. Launch them on demand
    #                           instead — the Win+B/S/D/C toggle binds already
    #                           do exactly that, and work-terminals.sh still
    #                           brings up the Salesforce twin when needed.
    #
    #   sleep 6 && workspace 1  only existed to pull focus back after the
    #                           autostarted apps had spawned. Nothing autostarts
    #                           now, so it has nothing to correct for.
  ];
}
