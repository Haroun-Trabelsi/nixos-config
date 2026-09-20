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

      # decoration.active_opacity/inactive_opacity apply globally, which is
      # wrong for anything whose pixels ARE the content: a washed-out photo or
      # video frame is a bug, not a style. Force these back to fully opaque.
      "match:class ^(imv)$, opacity 1.0"
      "match:class ^(mpv)$, opacity 1.0"
      "match:class ^(Aseprite)$, opacity 1.0"
      "match:class ^(Gimp-2.10)$, opacity 1.0"
      "match:title ^(Picture-in-Picture)$, opacity 1.0"

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
      # [Ss] because Spotify's Wayland app_id is lowercase "spotify" while its
      # older X11 class was "Spotify". This rule does currently land Spotify on
      # workspace 9, but the same capital-S assumption in toggle-music.sh was
      # silently broken, so match both rather than depend on which one wins.
      "match:class ^([Ss]potify)$, workspace 9"
      # No StartupWMClass upstream, so match both spellings (see the Spotify
      # note above and toggle-bitwarden.sh).
      "match:class ^([Bb]itwarden)$, workspace 2"

      "match:class ^(discord)$, workspace 10"
      "match:class ^(WebCord)$, workspace 10"
      "match:class ^(vesktop)$, workspace 10"

      "match:class ^(mpv)$, idle_inhibit focus"
      "match:class ^(zen)$, idle_inhibit fullscreen"

      "match:class ^(xdg-desktop-portal-gtk)$, dim_around on"

      "match:xwayland true, rounding 0"

      # Fullscreen only. A fullscreen window IS the screen, so a border and
      # rounded corners on it are just artefacts cutting into the content.
      #
      # The matching w[tv1] rules (= exactly one tiled window) were removed:
      # they stripped the border and rounding off any solo window, which is
      # why a single window looked flat and edge-to-edge. A lone window now
      # gets the same treatment as any other.
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

    # Gaps are collapsed for FULLSCREEN only (f[1]).
    #
    # "w[tv1], gapsout:0, gapsin:0" used to sit here too. w[tv1] matches a
    # workspace holding exactly one tiled window, so a solo window lost every
    # gap and sat flush against the screen edge — the usual Hyprland "no gaps
    # when only" idiom. Removed on purpose: gaps should not appear and vanish
    # depending on how many windows happen to be open.
    workspace = [
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
