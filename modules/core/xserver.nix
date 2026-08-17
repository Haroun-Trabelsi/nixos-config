{ pkgs, username, ... }:
{
  # services.xserver.enable is deliberately GONE. It was set with
  # displayManager.autoLogin and no display manager named, so NixOS fell through
  # to its default — LightDM — which meant a full X server stack running purely
  # to launch a Wayland session.
  #
  # greetd is a minimal daemon with no X dependency. initial_session logs
  # straight into sway (preserving the old autologin behaviour); default_session
  # is the tuigreet fallback shown if you log out.
  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "sway";
        user = username;
      };
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --cmd sway";
        user = "greeter";
      };
    };
  };

  # Still needed for libinput device handling under Wayland.
  services.libinput.enable = true;

  # swayosd needs this for caps/num/scroll-lock OSD, and brightnessctl's udev
  # rules are what let a non-root user (not in `video`) write to
  # /sys/class/backlight at all.
  services.udev.packages = [ pkgs.brightnessctl ];
  services.upower.enable = true;

  # Make the virtual-console (TTY) keymap match the French/AZERTY layout used in
  # the graphical session. Without this the TTY defaults to US/QWERTY, so console
  # login or recovery gets typed in the wrong layout (passwords look "wrong" and
  # letters come out scrambled). Ctrl+Alt+F-key rescue is now usable — and that
  # matters more with greetd, since a failed sway start drops you to a TTY.
  console.keyMap = "fr";

  # To prevent getting stuck at shutdown
  systemd.settings.Manager.DefaultTimeoutStopSec = "10s";
}
