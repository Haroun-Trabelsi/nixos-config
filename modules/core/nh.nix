{ username, ... }:
{
  programs.nh = {
    enable = true;
    # TEMPORARILY DISABLED for the sway/power migration. `--keep 5` will happily
    # garbage-collect the last known-good generation while we are relying on the
    # boot menu to roll back. Re-enable once the migration has settled.
    clean = {
      enable = false;
      extraArgs = "--keep-since 7d --keep 5";
    };
    flake = "/home/${username}/nixos-config";
  };
}
