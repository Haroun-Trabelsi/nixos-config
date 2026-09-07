{ pkgs, osConfig, ... }:
{
  wayland.windowManager.hyprland = {
    settings.monitor =
      if osConfig.machine.profile == "desktop" then
        [
          # Match by EDID description, NOT connector name: this RTX 5060 Ti
          # renumbers its outputs between driver versions. These same two
          # displays used to enumerate as DP-4 / HDMI-A-2 and now come up as
          # DP-1 / HDMI-A-1, which silently breaks any name-based rule.
          #
          # Primary: HP X24ih at its full 143.98 Hz, top-left origin.
          "desc:HP Inc. HP X24ih 1CR10516K5, 1920x1080@144, 0x0, 1"
          # TV as a left-hand extension. It MUST be driven at 1080p: its
          # preferred mode is 4K@30, and 4K@30 over HDMI emits NO SIGNAL on
          # this GPU (open Blackwell NVIDIA driver bug #1084). For real 4K,
          # use a DP->HDMI adapter instead. The garbage "XXX AAA" EDID is the
          # TV's own; it's unique among connected displays so it matches fine.
          # (4K@30 re-tested 2026-06-29: still NO SIGNAL. Scale 1 = no scaling.)
          "desc:XXX AAA, 1920x1080@60, auto-left, 1"
        ]
      else
        [
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
