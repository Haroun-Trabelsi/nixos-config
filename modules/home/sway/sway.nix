{
  pkgs,
  config,
  osConfig,
  lib,
  ...
}:
let
  c = config.theme.colors;
in
{
  wayland.windowManager.sway = {
    # laptop only — the desktop runs Hyprland
    enable = osConfig.machine.profile == "laptop";
    xwayland = true;
    systemd.enable = true;
    wrapperFeatures.gtk = true;

    # home-manager validates the generated config with `sway --validate` in a
    # sandbox where the outputs, fonts and cursor theme do not resolve, so a
    # perfectly good config fails to build. The real check is that sway starts.
    checkConfig = false;

    config = {
      modifier = "Mod4";
      terminal = "kitty";
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

  # Laptop only. This list was previously OUTSIDE the gate, so the tower was
  # carrying grimshot and wlsunset for a compositor it never runs. Everything
  # compositor-agnostic moved to modules/home/wayland-tools.nix (nwg-displays
  # included — hyprland/monitors.nix was adding it a second time); swappy and
  # playerctl are in packages/cli.nix and brightnessctl is in
  # machines/laptop/default.nix, so all three are dropped as duplicates.
  home.packages = lib.mkIf (osConfig.machine.profile == "laptop") (
    with pkgs;
    [
      # screenshots: grimblast is Hyprland-only, grimshot is its sway counterpart
      sway-contrib.grimshot
      wlsunset # night light, replacing noctalia's — driven by sway/startup.nix
    ]
  );
}
