{ ... }:
{
  wayland.windowManager.sway.config.startup = [
    # sway's systemd integration imports the environment and starts
    # sway-session.target, so the dbus-update-activation-environment and
    # `systemctl --user import-environment` lines from the Hyprland config are
    # no longer needed by hand.
    { command = "nm-applet --indicator"; }
    { command = "poweralertd"; }
    { command = "wl-clip-persist --clipboard both"; }
    { command = "wl-paste --watch cliphist store"; }
    { command = "udiskie --automount --notify --smart-tray"; }
    { command = "swayosd-server"; }

    # Night light. wlsunset is a tiny timer-driven C daemon; noctalia's version
    # was a feature of a whole QML shell.
    { command = "wlsunset -l 36.8 -L 10.2"; } # Africa/Tunis, matching time.timeZone
  ];

  # Still deliberately NOT autostarted (removed in the power phase, measured at
  # ~15 W for the wallpaper engine alone): no browser, no Spotify, no Discord,
  # no editor, no terminals. The toggle- binds launch them on demand.
  #
  # Also gone with noctalia: the shell process itself, its idle inhibitor, its
  # "performance" power profile, and monitor-watcher (a permanently running
  # socat on the Hyprland IPC socket whose only job was reapplying output
  # mirroring, which sway does not support anyway).
}
