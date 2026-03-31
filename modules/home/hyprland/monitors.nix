{ pkgs, ... }:
{
  wayland.windowManager.hyprland = {
    settings.monitor = [
      "desc:HP Inc. HP X24ih 1CR10516K5, 1920x1080@144, auto, 1"
      "eDP-1, preferred, auto, 1"
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
