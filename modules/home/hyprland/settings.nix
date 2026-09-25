{ ... }:
{
  wayland.windowManager.hyprland.settings = {
    input = {
      kb_options = "grp:alt_caps_toggle,caps:capslock";
      kb_layout = "fr";
      repeat_delay = 300;
      numlock_by_default = true;

      follow_mouse = 1;
      mouse_refocus = 0;
      float_switch_override_focus = 0;

      touchpad = {
        disable_while_typing = false;
        natural_scroll = true;
      };
    };
    cursor = {
      no_hardware_cursors = true;
    };

    general = {
      layout = "dwindle";

      # Was 3/5, which read as "no gaps at all" on a 1920x1080 panel. Those
      # values came from the laptop's ~10 W power target; this module is gated
      # on `machine.profile == "desktop"` and only ever runs on the tower, so
      # that rationale had already stopped applying.
      gaps_in = 6;
      gaps_out = 16;
      border_size = 2;

      "col.active_border" = "rgb(c6a0f6) rgb(ed8796) 45deg";
      # Was fully transparent, so unfocused windows had no edge at all and
      # bled into the wallpaper. Low-alpha overlay from the Eldritch palette
      # gives them a quiet outline without competing with the active border.
      "col.inactive_border" = "rgba(3b426199)";
    };

    misc = {
      # Never let the machine end up with dark screens and no way back. These
      # tell Hyprland itself to undo a DPMS-off on the first mouse move or
      # keypress, independent of whoever turned the displays off — so a dead or
      # misconfigured swayidle can no longer cost a hard reset. Both default to
      # false.
      mouse_move_enables_dpms = true;
      key_press_enables_dpms = true;

      disable_hyprland_logo = true;
      disable_splash_rendering = false;

      focus_on_activate = true;
      middle_click_paste = false;

      disable_autoreload = false;
    };

    # Mirror the log to stdout, which greetd routes into the journal via
    # systemd-cat (modules/core/session.nix), so it outlives a hard reset.
    # disable_logs stays at its default (true), which keeps this to the startup
    # and backend (aquamarine/DRM) lines: a few hundred per session.
    debug = {
      enable_stdout_logs = true;
    };

    dwindle = {
      force_split = 2;
      preserve_split = true;
      use_active_for_splits = true;
    };

    master = {
      new_status = "master";
    };

    decoration = {
      # 4 was barely visible. 12 reads as an intentional radius and sits closer
      # to noctalia's own frameRadius (24) without looking like a pill.
      rounding = 12;

      # Blur and shadows were both off for the laptop's ~10 W power target.
      # That target does not exist here: this module only loads when
      # machine.profile == "desktop", i.e. a mains-powered RTX 5060 Ti.
      # `xray = true` is the costly bit — it re-blurs the full screen whenever
      # anything *behind* a window changes — but it is also what makes the blur
      # sample the wallpaper rather than the stacked windows, which is the look
      # worth having. Set xray = false first if you ever want the cost back down.
      blur = {
        enabled = true;

        # size x passes is the effective radius. 3/2 was tuned to be cheap, not
        # to be seen; 6/3 is a soft frosted pane that still reads as "a bit".
        size = 6;
        passes = 3;

        noise = 0;
        contrast = 1.4;
        brightness = 1;

        xray = true;
      };

      # Hyprland blur only affects TRANSLUCENT surfaces — it composites what is
      # behind a window, so on a fully opaque window there is nothing to show
      # and `blur.enabled` is a silent no-op. Nothing here was translucent
      # (kitty.nix even pins background_opacity = "1.0"), so the blur above
      # does nothing without these two lines.
      #
      # Deliberately subtle: 0.95/0.88 is enough to let the blurred wallpaper
      # register behind text without hurting contrast. Push inactive_opacity
      # lower for a stronger effect; leave active_opacity near 1 or long
      # reading sessions get tiring.
      active_opacity = 0.95;
      inactive_opacity = 0.88;

      # Fullscreen is the one place translucency is always wrong — a fullscreen
      # video or game should be exactly its own pixels.
      fullscreen_opacity = 1.0;

      shadow = {
        enabled = true;

        range = 20;
        render_power = 3;

        offset = "0 2";
        color = "rgba(00000055)";
      };
    };

    animations = {
      # Was false. The stated reason — animations hold the GPU out of its idle
      # state — was a battery argument, and this module is desktop-only, so it
      # never applied to the machine that actually runs it.
      enabled = true;

      bezier = [
        "fluent_decel, 0, 0.2, 0.4, 1"
        "easeOutCirc, 0, 0.55, 0.45, 1"
        "easeOutCubic, 0.33, 1, 0.68, 1"
        "fade_curve, 0, 0.55, 0.45, 1"
      ];

      animation = [
        # name, enable, speed, curve, style

        # Windows
        "windowsIn,   1, 4, easeOutCubic,  popin 20%" # window open
        "windowsOut,  1, 4, fluent_decel,  popin 80%" # window close.
        "windowsMove, 1, 2, fluent_decel, slide" # everything in between, moving, dragging, resizing.

        # Fade
        "fadeIn,      1, 3,   fade_curve" # fade in (open) -> layers and windows
        "fadeOut,     1, 3,   fade_curve" # fade out (close) -> layers and windows
        "fadeSwitch,  1, 1,   easeOutCirc" # fade on changing activewindow and its opacity
        "fadeShadow,  1, 10,  easeOutCirc" # fade on changing activewindow for shadows
        "fadeDim,     1, 4,   fluent_decel" # the easing of the dimming of inactive windows
        # "border,      1, 2.7, easeOutCirc"  # for animating the border's color switch speed
        # "borderangle, 1, 30,  fluent_decel, once" # for animating the border's gradient angle - styles: once (default), loop
        # Workspace switching slides the whole viewport sideways ("swipe")
        # instead of cross-fading in place. Speed 5 (~500ms) rather than 4,
        # because a slide needs longer than a fade to read as motion instead
        # of a jump. Styles: slide, slidevert, fade, slidefade, slidefadevert.
        "workspaces,  1, 5,   easeOutCubic, slide"
        # The special/scratchpad workspace comes from above rather than the
        # side, so it reads as a different kind of thing.
        "specialWorkspace, 1, 5, easeOutCubic, slidevert"
      ];
    };

    xwayland = {
      force_zero_scaling = true;
    };
  };
}
