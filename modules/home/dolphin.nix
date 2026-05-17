{ pkgs, lib, ... }:
{
  home.packages = with pkgs; [
    kdePackages.dolphin
    (tela-circle-icon-theme.override { colorVariants = [ "purple" ]; })
  ];

  # Point Dolphin at noctalia's color scheme + Tela icons.
  # kwriteconfig6 merges into kdeglobals (no plasma-workspace needed).
  home.activation.setKdePrefs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 \
      --file kdeglobals --group General --key ColorScheme Noctalia
    run ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 \
      --file kdeglobals --group Icons --key Theme Tela-circle-purple-dark
  '';
}
