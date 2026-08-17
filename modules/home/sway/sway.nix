{ pkgs, config, ... }:
let
  c = config.theme.colors;
in
{
  wayland.windowManager.sway = {
    enable = true;
    xwayland = true;
    systemd.enable = true;
    wrapperFeatures.gtk = true;

    # home-manager validates the generated config with `sway --validate` in a
    # sandbox where the outputs, fonts and cursor theme do not resolve, so a
    # perfectly good config fails to build. The real check is that sway starts.
    checkConfig = false;

    config = {
      modifier = "Mod4";
      terminal = "ghostty";
      menu = "fuzzel";

      gaps = {
        inner = 3;
        outer = 5;
        # Replaces the eight "no gaps when only" workspace rules the Hyprland
        # config needed: one window on a workspace gets no gaps and no border.
        smartGaps = true;
        smartBorders = "on";
      };

      window = {
        border = 2;
        titlebar = false;
      };
      floating = {
        border = 2;
        titlebar = false;
      };

      colors = {
        focused = {
          border = c.tertiary;
          background = c.base;
          text = c.text;
          indicator = c.primary;
          childBorder = c.tertiary;
        };
        focusedInactive = {
          border = c.surface;
          background = c.base;
          text = c.subtext;
          indicator = c.surface;
          childBorder = c.surface;
        };
        unfocused = {
          border = c.surface;
          background = c.base;
          text = c.subtext;
          indicator = c.surface;
          childBorder = c.surface;
        };
        urgent = {
          border = c.error;
          background = c.base;
          text = c.text;
          indicator = c.error;
          childBorder = c.error;
        };
      };
    };

    extraConfig = ''
      # Hyprland's `focus_on_activate` equivalent.
      focus_on_window_activation focus

      # No blur, no shadows, no animations, no rounding — that is the point of
      # this migration, and sway has none of them to disable.
    '';
  };

  home.packages = with pkgs; [
    # screenshots: grimblast is Hyprland-only, grimshot is its sway counterpart
    sway-contrib.grimshot
    grim
    slurp
    swappy
    wl-clipboard
    wl-clip-persist
    cliphist
    wf-recorder
    hyprpicker # compositor-agnostic colour picker despite the name
    tesseract # OCR
    wlsunset # night light, replacing noctalia's
    brightnessctl
    playerctl
    nwg-displays
  ];
}
