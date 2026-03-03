{ lib, pkgs, host, ... }:
{
  home.pointerCursor = {
    name = "Nordzy-catppuccin-macchiato-dark";
    package = pkgs.nordzy-cursor-theme;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  fonts.fontconfig.enable = true;
  home.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.caskaydia-cove
    nerd-fonts.symbols-only
    twemoji-color-font
    noto-fonts-color-emoji
    fantasque-sans-mono
    maple-mono-custom
    monocraft
  ];

  gtk = {
    enable = true;
    iconTheme = {
      name = "pixelitos-dark";
      package = pkgs.pixelitos;
    };
    font = {
      name = "Monocraft";
      size = if (host == "p14s") then 14 else 12;
    };
    gtk3 = {
      extraConfig = {
        gtk-application-prefer-dark-theme = lib.mkForce true;
      };
    };

    gtk4 = {
      extraConfig = {
        gtk-application-prefer-dark-theme = lib.mkForce true;
      };
    };
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };
}
