{ pkgs, ... }:
{
  wayland.windowManager.hyprland = {
    settings.monitor = [
      "eDP-1, preferred, auto, 1"
      ",preferred,auto,1,mirror,eDP-1"
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
