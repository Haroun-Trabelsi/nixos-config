{ pkgs, inputs, ... }:
{
  imports = [ inputs.hyprland.nixosModules.default ];

  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.x86_64-linux.hyprland;
    portalPackage = inputs.hyprland.packages.x86_64-linux.xdg-desktop-portal-hyprland;
  };

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = false;
    config = {
      common.default = [ "gtk" ];
      hyprland = {
        default = [
          "gtk"
          "hyprland"
        ];
        "org.freedesktop.impl.portal.OpenURI" = [ "gnome" ];
      };
    };

    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-gnome
    ];
  };
}
