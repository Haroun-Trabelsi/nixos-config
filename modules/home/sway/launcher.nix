{ config, ... }:
let
  c = config.theme.colors;
  strip = h: builtins.substring 1 6 h; # fuzzel wants RRGGBBAA without the '#'
in
{
  # fuzzel rather than wofi/rofi: it is Wayland-native with no toolkit, and it
  # EXITS after each use, so its idle cost is exactly zero. noctalia's launcher
  # was part of a resident QML process.
  #
  # It also serves as the dmenu for the clipboard picker and the power menu,
  # which is why scripts/scripts/{power-menu,clipboard-picker}.sh call it.
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        terminal = "ghostty -e";
        layer = "overlay";
        width = 45;
        lines = 12;
        font = "JetBrainsMono Nerd Font:size=12";
        prompt = "'  '";
      };
      colors = {
        background = "${strip c.mantle}f0";
        text = "${strip c.text}ff";
        match = "${strip c.primary}ff";
        selection = "${strip c.surface}ff";
        selection-text = "${strip c.text}ff";
        selection-match = "${strip c.primary}ff";
        border = "${strip c.tertiary}ff";
      };
      border = {
        width = 2;
        radius = 8;
      };
    };
  };
}
