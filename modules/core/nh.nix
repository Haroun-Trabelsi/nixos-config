{ username, ... }:
{
  programs.nh = {
    enable = true;
    # Re-enabled: the sway/power migration it was switched off for has landed.
    # `--keep-since 7d --keep 5` is the safe form for a machine whose rollback
    # path is the boot menu — it keeps five generations AND everything from the
    # last week, so a generation you might want to boot back into is never the
    # one collected. Left off, the store grows without bound.
    clean = {
      enable = true;
      extraArgs = "--keep-since 7d --keep 5";
    };
    flake = "/home/${username}/nixos-config";
  };
}
