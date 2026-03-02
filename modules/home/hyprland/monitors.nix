{ pkgs, ... }:
{
  wayland.windowManager.hyprland = {
    settings.monitor = [
      "monitor = eDP-1, preferred, auto, 0.8"
      "monitor = HDMI-A-1, 1920x1080@144, auto, 0.9"
      ",preferred,auto,auto"
    ];

    extraConfig = ''
      # hyprlang noerror true
        source = ~/.config/hypr/monitors.conf
        source = ~/.config/hypr/workspaces.conf
      # hyprlang noerror false
    '';
  };

  home.packages = with pkgs; [ nwg-displays ];
}
