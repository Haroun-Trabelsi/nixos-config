{
  pkgs,
  config,
  lib,
  osConfig,
  ...
}:
let
  c = config.theme.colors;
  lock = "${pkgs.swaylock}/bin/swaylock -f";
  isLaptop = osConfig.machine.profile == "laptop";
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

  # The idle ladder, and it is deliberately NOT the same on both machines.
  #
  # LAPTOP (36.6 Wh battery): the full ladder. DPMS-off alone is worth ~1.5 W at
  # low brightness and ~5 W at full, and suspend is what makes an overnight
  # closed lid survivable.
  #
  # DESKTOP: nothing turns the displays off, ever. The outputs keep scanning out
  # for as long as the session is up; the monitors' own power buttons are the
  # off switch, which costs the GPU a couple of watts and cannot strand the
  # session behind a display the driver refuses to bring back. The auto-suspend
  # that did exactly that is gone too — see the note on the suspend rung below.
  #
  # Video playback is protected by the `inhibit_idle` window rules in rules.nix,
  # which is the sway equivalent of Hyprland's idle_inhibit.
  #
  # Waking up (laptop): swayidle fires `resume` on the first input event of any
  # kind, so a mouse nudge or a keypress runs `dpms on`. Hyprland's own
  # misc:{mouse_move,key_press}_enables_dpms (settings.nix) is the second belt
  # for that, in case swayidle is dead or its command fails.
  services.swayidle = {
    enable = true;
    # attrset keyed by event name; the list-of-{event,command} form is deprecated
    events = {
      before-sleep = lock;
      lock = lock;
    };
    timeouts =
      # Screen-off is LAPTOP-ONLY: this is the battery rung, and the desktop is
      # asked to keep a signal on the wire at all times.
      # `dpms` detects sway vs Hyprland at runtime, so it must not hardcode
      # swaymsg even though only sway reaches it today.
      lib.optional isLaptop {
        timeout = 300; # 5 min — screen off
        command = "dpms off";
        resumeCommand = "dpms on";
      }
      ++ [
        {
          timeout = 600; # 10 min — lock
          command = lock;
        }
      ]
      # Suspend is LAPTOP-ONLY too. On the tower it was a guaranteed
      # force-shutdown: the machine reached S3 fine, but the NVIDIA driver could
      # not bring the displays back on resume —
      #   nv_drm_atomic_apply_modeset_config: Failed to initialize semaphore for
      #   plane fence / Failed to apply atomic modeset. Error code: -11
      # followed by Xid 13 and Hyprland aborting (SIGABRT). Both hard resets on
      # 2026-09-08 and 2026-09-09 came from exactly this, and a mains-powered
      # tower has nothing to gain from a 30-minute auto-suspend.
      ++ lib.optional isLaptop {
        timeout = 1800; # 30 min — suspend (S3, see machines/laptop/power.nix)
        command = "${pkgs.systemd}/bin/systemctl suspend";
      };
  };

  # swayidle runs every timeout command through `sh -c`, inheriting the unit's
  # PATH — and home-manager sets that to bash and nothing else. So `dpms off`
  # and `dpms on` never ran at all:
  #   swayidle[32663]: bash: line 1: dpms: command not found
  # The screen going dark was never DPMS; it was the suspend rung above. Put the
  # user profile on the unit's PATH so `dpms` resolves, and with it the bare
  # `hyprctl` / `swaymsg` the script itself calls.
  systemd.user.services.swayidle.Service.Environment = lib.mkForce [
    "PATH=${config.home.profileDirectory}/bin:/run/current-system/sw/bin"
  ];
}
