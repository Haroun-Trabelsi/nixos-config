{ osConfig, ... }:
{
  wayland.windowManager.hyprland.settings = {
    windowrule = [
      "match:class ^(imv)$, float on"
      "match:class ^(mpv)$, float on"
      "match:class ^(zenity)$, float on"
      "match:class ^(waypaper)$, float on"
      "match:class ^(SoundWireServer)$, float on"
      "match:class ^(.sameboy-wrapped)$, float on"
      "match:class ^(org.gnome.Calculator)$, float on"
      "match:class ^(org.gnome.FileRoller)$, float on"
      "match:class ^(org.pulseaudio.pavucontrol)$, float on"
      "match:class ^(openrgb)$, float on"

      "match:class ^(waypaper)$, pin on"

      "match:class ^(Aseprite)$, tile on"

      "match:class ^(zenity)$, size 850 500"
      "match:class ^(SoundWireServer)$, size 725 330"

      "match:title ^(Volume Control)$, size 700 450"
      "match:title ^(Volume Control)$, move 40 55%"

      "match:title ^(Picture-in-Picture)$, pin on"
      "match:title ^(Picture-in-Picture)$, float on"

      "match:class ^(Gimp-2.10)$, workspace 4"
      "match:class ^(Aseprite)$, workspace 4"
      "match:class ^(Audacious)$, workspace 5"
      "match:class ^(GitHub Desktop)$, workspace 6"
      "match:class ^(codium)$, workspace 8"
      "match:class ^(com.obsproject.Studio)$, workspace 8"
      "match:class ^(Spotify)$, workspace 9"
      "match:class ^(discord)$, workspace 10"
      "match:class ^(WebCord)$, workspace 10"
      "match:class ^(vesktop)$, workspace 10"

      "match:class ^(mpv)$, idle_inhibit focus"
      "match:class ^(zen)$, idle_inhibit fullscreen"

      "match:class ^(xdg-desktop-portal-gtk)$, dim_around on"

      "match:xwayland true, rounding 0"

      # No gaps when only
      "border_size 0, match:float 0, match:workspace w[tv1]"
      "rounding 0, match:float 0, match:workspace w[tv1]"
      "border_size 0, match:float 0, match:workspace f[1]"
      "rounding 0, match:float 0, match:workspace f[1]"
    ];

    layerrule = [
      "match:namespace swaync-control-center, dim_around on"

      # noctalia shell background + blur
      "match:namespace ^(noctalia-background-.*)$, blur on"
      "match:namespace ^(noctalia-background-.*)$, blur_popups on"
      "match:namespace ^(noctalia-background-.*)$, ignore_alpha 0.5"
    ];

    # No gaps when only
    workspace =
      [
        "w[tv1], gapsout:0, gapsin:0"
        "f[1], gapsout:0, gapsin:0"
      ]
      # Desktop: pin workspaces to monitors so the HP is primary. Without this,
      # Hyprland gives workspace 1 to whichever output initializes first — the
      # TV (HDMI) — leaving the HP stuck on workspace 2. Monitors are matched by
      # EDID description (see monitors.nix for why connector names aren't stable).
      # WS3 is the TV's own workspace (reach it with Super+3); everything else
      # lives on the HP, which owns WS1 as its default.
      ++ (
        if osConfig.machine.profile == "desktop" then
          [
            "1, monitor:desc:HP Inc. HP X24ih 1CR10516K5, default:true"
            "2, monitor:desc:HP Inc. HP X24ih 1CR10516K5"
            "3, monitor:desc:XXX AAA, default:true"
            "4, monitor:desc:HP Inc. HP X24ih 1CR10516K5"
            "5, monitor:desc:HP Inc. HP X24ih 1CR10516K5"
            "6, monitor:desc:HP Inc. HP X24ih 1CR10516K5"
            "7, monitor:desc:HP Inc. HP X24ih 1CR10516K5"
            "8, monitor:desc:HP Inc. HP X24ih 1CR10516K5"
            "9, monitor:desc:HP Inc. HP X24ih 1CR10516K5"
            "10, monitor:desc:HP Inc. HP X24ih 1CR10516K5"
          ]
        else
          [ ]
      );
  };
}
