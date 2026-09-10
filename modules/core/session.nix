{
  config,
  pkgs,
  username,
  ...
}:
# Login and session plumbing: greetd, libinput, the TTY keymap, shutdown timeout.
#
# Renamed from xserver.nix, which was actively misleading — there is no X server
# here and `services.xserver.enable` is deliberately unset (see below).
let
  # Hyprland on the tower, sway on the laptop.
  #
  # Hyprland is launched via `start-hyprland`, NOT the `Hyprland` binary
  # directly. start-hyprland is upstream's watchdog: it forks the compositor and
  # restarts it if it dies uncleanly, so an NVIDIA driver hiccup costs you your
  # windows instead of your whole session. Launching Hyprland bare logs
  # "WARNING: Hyprland is being launched without start-hyprland" and gives up the
  # watchdog entirely. nixpkgs' own hyprland.desktop session file execs
  # start-hyprland for exactly this reason; greetd was bypassing it.
  # A clean exit (logout) still exits cleanly, so greetd re-runs default_session
  # and the autologin loop below is unchanged.
  compositor = if config.machine.profile == "desktop" then "start-hyprland" else "sway";
in
{
  # services.xserver.enable is deliberately GONE. It was set with
  # displayManager.autoLogin and no display manager named, so NixOS fell through
  # to its default — LightDM — which meant a full X server stack running purely
  # to launch a Wayland session.
  #
  # greetd is a minimal daemon with no X dependency. initial_session logs
  # straight into sway (preserving the old autologin behaviour); default_session
  # is the tuigreet fallback shown if you log out.
  # No login prompt, ever. initial_session covers the first session after boot;
  # default_session is set to the SAME thing so logging out drops straight back
  # in rather than falling through to a greeter. This restores the behaviour of
  # the old displayManager.autoLogin.
  #
  # Trade-off, stated plainly: anyone who boots this machine lands in the
  # session. The running session is still guarded by swaylock (Win+Escape, and
  # the idle ladder). If the compositor ever fails to start, greetd will retry
  # and then give up — recover on another VT with Ctrl+Alt+F2, or pick an older
  # generation from the boot menu.
  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = compositor;
        user = username;
      };
      default_session = {
        command = compositor;
        user = username;
      };
    };
  };

  # Still needed for libinput device handling under Wayland.
  services.libinput.enable = true;

  # swayosd needs this for caps/num/scroll-lock OSD, and brightnessctl's udev
  # rules are what let a non-root user (not in `video`) write to
  # /sys/class/backlight at all.
  services.udev.packages = [ pkgs.brightnessctl ];

  # Make the virtual-console (TTY) keymap match the French/AZERTY layout used in
  # the graphical session. Without this the TTY defaults to US/QWERTY, so console
  # login or recovery gets typed in the wrong layout (passwords look "wrong" and
  # letters come out scrambled). Ctrl+Alt+F-key rescue is now usable — and that
  # matters more with greetd, since a failed sway start drops you to a TTY.
  console.keyMap = "fr";

  # To prevent getting stuck at shutdown
  systemd.settings.Manager.DefaultTimeoutStopSec = "10s";
}
