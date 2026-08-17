{ lib, ... }:
# Single source of truth for colours.
#
# This replaces noctalia's template engine, which rewrote theme files for kitty,
# btop, qt5ct/qt6ct, gtk, vscode, discord, spicetify and steam at RUNTIME from a
# QML process. Two problems with that: every themed app depended on a running
# shell, and the output had already drifted from the declared palette — the
# config declared Eldritch (mSurface #212337) while the generated kitty theme
# contained a wallpaper-derived #070722.
#
# Here the palette is fixed at build time and consumers read it from
# `config.theme.colors`. Trade-off, stated plainly: no more wallpaper-derived
# colours and no runtime dark/light toggle. In exchange the theme is
# reproducible and nothing depends on a shell process being alive.
#
# Values mirror noctalia's Eldritch scheme, which is what the config asked for.
{
  options.theme.colors = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    description = "Frozen Eldritch palette, consumed at build time by every themed module.";
    default = {
      # Accents
      primary = "#37f499"; # green
      secondary = "#04d1f9"; # cyan
      tertiary = "#a48cf2"; # purple
      error = "#f16c75"; # red
      warning = "#f1fc79"; # yellow

      # Surfaces
      base = "#212337"; # window / terminal background
      mantle = "#171928"; # deeper background, bar
      surface = "#292e42"; # raised surface
      overlay = "#3b4261"; # borders, outlines
      shadow = "#414868";

      # Text
      text = "#ebfafa";
      subtext = "#abb4da";
      inverse = "#171928"; # text on an accent-coloured background

      # ANSI 0-15, for terminals
      black = "#212337";
      red = "#f16c75";
      green = "#37f499";
      yellow = "#f1fc79";
      blue = "#a48cf2";
      magenta = "#f265b5";
      cyan = "#04d1f9";
      white = "#ebfafa";
      brightBlack = "#414868";
      brightRed = "#f16c75";
      brightGreen = "#37f499";
      brightYellow = "#f1fc79";
      brightBlue = "#a48cf2";
      brightMagenta = "#f265b5";
      brightCyan = "#04d1f9";
      brightWhite = "#ffffff";
    };
  };
}
