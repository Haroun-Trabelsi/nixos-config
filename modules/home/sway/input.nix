{ ... }:
{
  wayland.windowManager.sway.config = {
    input = {
      "type:keyboard" = {
        xkb_layout = "fr";
        xkb_options = "grp:alt_caps_toggle,caps:capslock";
        xkb_numlock = "enabled";
        repeat_delay = "300";
      };

      "type:touchpad" = {
        natural_scroll = "enabled";
        dwt = "disabled"; # disable-while-typing was off in the Hyprland config
        tap = "enabled";
        scroll_method = "two_finger";
      };
    };

    seat."seat0" = {
      xcursor_theme = "Nordzy-catppuccin-macchiato-dark 24";

      # Replaces `hyprctl setcursor` from exec-once, and hides the pointer after
      # 5 s of inactivity. That is a real power item, not just cosmetics: a
      # visible cursor keeps its plane updating, which stops the screen ever
      # being fully static and defeats panel self-refresh.
      hide_cursor = "5000";
    };

    focus = {
      followMouse = true;
      mouseWarping = false;
      # Hyprland's float_switch_override_focus = 0
      newWindow = "smart";
    };
  };

  wayland.windowManager.sway.extraConfig = ''
    # Hyprland used bindm for these; in sway one directive covers both:
    # Super+left-drag moves, Super+right-drag resizes.
    floating_modifier Mod4 normal
  '';
}
