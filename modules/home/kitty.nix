{ config, ... }:
let
  c = config.theme.colors;
in
{
  programs.kitty = {
    enable = true;

    font = {
      name = "Monocraft";
      size = 14;
    };

    # Was `include themes/noctalia.conf`, a file rewritten at runtime by the
    # noctalia QML process. Colours now come from modules/home/theme.nix at
    # build time, so kitty no longer depends on a shell process being alive.

    settings = {
      # --- colours (from modules/home/theme.nix) ---
      background = c.base;
      foreground = c.text;
      cursor = c.primary;
      selection_background = c.overlay;
      selection_foreground = c.text;
      color0 = c.black;
      color1 = c.red;
      color2 = c.green;
      color3 = c.yellow;
      color4 = c.blue;
      color5 = c.magenta;
      color6 = c.cyan;
      color7 = c.white;
      color8 = c.brightBlack;
      color9 = c.brightRed;
      color10 = c.brightGreen;
      color11 = c.brightYellow;
      color12 = c.brightBlue;
      color13 = c.brightMagenta;
      color14 = c.brightCyan;
      color15 = c.brightWhite;

      confirm_os_window_close = 0;
      # Opaque so the compositor can bound damage to the terminal rectangle.
      # With a transparent surface every cursor blink forces everything beneath
      # it to be recomposited too.
      background_opacity = "1.0";
      scrollback_lines = 10000;
      enable_audio_bell = false;
      mouse_hide_wait = 60;
      window_padding_width = 10;

      ## Tabs
      tab_title_template = "{index}";
      active_tab_font_style = "normal";
      inactive_tab_font_style = "normal";
      tab_bar_style = "powerline";
      tab_powerline_style = "angled";
    };

    keybindings = {
      ## Tabs
      "alt+1" = "goto_tab 1";
      "alt+2" = "goto_tab 2";
      "alt+3" = "goto_tab 3";
      "alt+4" = "goto_tab 4";

      ## Unbind
      "ctrl+shift+left" = "no_op";
      "ctrl+shift+right" = "no_op";
    };
  };
}
