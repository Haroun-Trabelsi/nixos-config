{ pkgs, config, ... }:
let
  c = config.theme.colors;
  lock = "${pkgs.swaylock}/bin/swaylock -f";
in
{
  # Shared by BOTH machines (sway on the laptop, Hyprland on the desktop):
# swaylock speaks ext-session-lock-v1, which Hyprland implements too.
# swaylock replaces hyprlock. Solid colour rather than swaylock-effects'
  # screenshot-and-blur pass, which costs a full-screen GPU operation every time
  # the screen locks.
  programs.swaylock = {
    enable = true;
    settings = {
      color = builtins.substring 1 6 c.mantle;
      indicator-radius = 90;
      indicator-thickness = 10;
      ring-color = builtins.substring 1 6 c.surface;
      key-hl-color = builtins.substring 1 6 c.primary;
      line-color = "00000000";
      inside-color = builtins.substring 1 6 c.base;
      text-color = builtins.substring 1 6 c.text;
      separator-color = "00000000";
      show-failed-attempts = true;
      ignore-empty-password = true;
    };
  };

  # The idle ladder. This did not exist before in any form: noctalia's idle
  # block was commented out AND the session actively enabled an idle inhibitor
  # at login, so the screen never blanked and the machine never slept. On a
  # 36.6 Wh battery, DPMS-off alone is worth ~1.5 W at low brightness and ~5 W
  # at full.
  #
  # Video playback is protected by the `inhibit_idle` window rules in rules.nix,
  # which is the sway equivalent of Hyprland's idle_inhibit.
  services.swayidle = {
    enable = true;
    # attrset keyed by event name; the list-of-{event,command} form is deprecated
    events = {
      before-sleep = lock;
      lock = lock;
    };
    timeouts = [
      {
        timeout = 300; # 5 min — screen off
        # `dpms` detects sway vs Hyprland at runtime — this ladder is shared
        # by both machines, so it must not hardcode swaymsg.
        command = "dpms off";
        resumeCommand = "dpms on";
      }
      {
        timeout = 600; # 10 min — lock
        command = lock;
      }
      {
        timeout = 1800; # 30 min — suspend (S3, see machines/laptop/power.nix)
        command = "${pkgs.systemd}/bin/systemctl suspend";
      }
    ];
  };
}
