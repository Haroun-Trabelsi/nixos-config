{ pkgs, ... }:
{
  # qylock is a themed Quickshell-based lockscreen.
  # Package lives at pkgs/qylock (registered via the custom overlay).
  # mpvpaper drives the animated Hollow Knight wallpaper (bg.mp4 shipped
  # by the pixel-hollowknight qylock theme) — see exec-once.nix.
  home.packages = [
    pkgs.qylock
    pkgs.mpvpaper
  ];

  # Persist the selected theme — lock.sh reads this on every invocation.
  xdg.configFile."qylock/theme".text = "pixel-hollowknight";
}
