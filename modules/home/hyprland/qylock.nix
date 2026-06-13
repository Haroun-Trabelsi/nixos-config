{ pkgs, ... }:
{
  # qylock is a themed Quickshell-based lockscreen.
  # Package lives at pkgs/qylock (registered via the custom overlay).
  home.packages = [
    pkgs.qylock
  ];

  # Persist the selected theme — lock.sh reads this on every invocation.
  xdg.configFile."qylock/theme".text = "pixel-hollowknight";
}
