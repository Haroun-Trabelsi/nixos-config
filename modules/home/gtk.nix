{
  lib,
  pkgs,
  ...
}:
{
  home.pointerCursor = {
    enable = true;
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
    jetbrains-mono
    # For Edge's web-content font (modules/home/edge.nix profile fix,
    # 2026-09-19) — the desktop's own font (below) is JetBrains Mono
    # deliberately, but that inheriting into rendered WEB PAGES (Chromium
    # reads GTK's font on Linux when nothing overrides it) is what made body
    # text look wrong: proportional prose in a monospace font.
    roboto
  ];

  gtk = {
    enable = true;
    iconTheme = {
      name = "Tela-circle-purple-dark";
      package = pkgs.tela-circle-icon-theme.override { colorVariants = [ "purple" ]; };
    };
    font = {
      name = "Jetbrains Mono";
      # was `if host == "p14s" then 14 else 12`; the p14s host is gone
      size = 12;
    };
    gtk3 = {
      extraConfig = {
        gtk-application-prefer-dark-theme = true;
      };
    };

    gtk4 = {
      extraConfig = {
        gtk-application-prefer-dark-theme = true;
      };
    };
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };
}
