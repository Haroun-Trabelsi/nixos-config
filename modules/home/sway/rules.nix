{ ... }:
{
  # IMPORTANT: Wayland clients match on `app_id`, Xwayland clients on `class`.
  # Getting this wrong is the most likely cause of a rule silently not firing.
  # Audit the real values once sway is running with:
  #   swaymsg -t get_tree | jq '.. | select(.pid?) | {app_id, class, name}'
  #
  # Known at time of writing: Spotify and GitHub Desktop are X11 (class);
  # vesktop and dolphin are Wayland (app_id); VS Code under NIXOS_OZONE_WL is
  # app_id "code" — the old Hyprland rule matched class "code", which would not
  # have fired under Wayland either.
  wayland.windowManager.sway.config = {
    floating.criteria = [
      { app_id = "^imv$"; }
      { app_id = "^mpv$"; }
      { app_id = "^zenity$"; }
      { app_id = "^org\\.gnome\\.Calculator$"; }
      { app_id = "^org\\.gnome\\.FileRoller$"; }
      { app_id = "^org\\.pulseaudio\\.pavucontrol$"; }
      { app_id = "^ghostty-float$"; }
      { class = "^SoundWireServer$"; }
      { class = "^openrgb$"; }
      { class = "^\\.sameboy-wrapped$"; }
      { title = "^Picture-in-Picture$"; }
    ];

    window.commands = [
      # sizes / placement
      {
        criteria.app_id = "^ghostty-float$";
        command = "resize set 1111 700, move position center";
      }
      {
        criteria.app_id = "^ghostty-full$";
        command = "fullscreen enable";
      }
      {
        criteria.app_id = "^zenity$";
        command = "resize set 850 500";
      }
      {
        criteria.class = "^SoundWireServer$";
        command = "resize set 725 330";
      }
      {
        criteria.title = "^Volume Control$";
        command = "resize set 700 450";
      }
      {
        criteria.title = "^Picture-in-Picture$";
        command = "sticky enable";
      }

      # workspace assignment. `for_window ... move container` is used rather than
      # `assign`, because assign only fires at map time and Electron/Spotify
      # windows re-map after their splash, which assign misses.
      {
        criteria.class = "^Gimp-2\\.10$";
        command = "move container to workspace number 4";
      }
      {
        criteria.class = "^Aseprite$";
        command = "move container to workspace number 4";
      }
      {
        criteria.class = "^Audacious$";
        command = "move container to workspace number 5";
      }
      {
        criteria.class = "^GitHub Desktop$";
        command = "move container to workspace number 6";
      }
      {
        criteria.app_id = "^code$";
        command = "move container to workspace number 8";
      }
      {
        criteria.class = "^code$";
        command = "move container to workspace number 8";
      }
      {
        # Zed's Wayland app_id. Verify with `swaymsg -t get_tree` on first run;
        # if it differs, this rule and toggle-zed both need the real value.
        criteria.app_id = "^dev\\.zed\\.Zed$";
        command = "move container to workspace number 8";
      }
      {
        criteria.app_id = "^com\\.obsproject\\.Studio$";
        command = "move container to workspace number 8";
      }
      {
        criteria.class = "^Spotify$";
        command = "move container to workspace number 9";
      }
      {
        criteria.app_id = "^vesktop$";
        command = "move container to workspace number 10";
      }
      {
        criteria.class = "^discord$";
        command = "move container to workspace number 10";
      }

      # Idle inhibition. This is the exact equivalent of Hyprland's
      # `idle_inhibit focus`, and it is what stops swayidle blanking the screen
      # mid-video — important now that the login idle-inhibitor is gone.
      {
        criteria.app_id = "^mpv$";
        command = "inhibit_idle focus";
      }
      {
        criteria.app_id = "^thorium-browser$";
        command = "inhibit_idle fullscreen";
      }
      {
        criteria.class = "^thorium-browser$";
        command = "inhibit_idle fullscreen";
      }

      # Aseprite explicitly tiles
      {
        criteria.class = "^Aseprite$";
        command = "floating disable";
      }
    ];

    # Dropped with no equivalent, deliberately:
    #   dim_around      — no sway equivalent
    #   rounding 0 on xwayland — there is no rounding at all now
    #   the four "no gaps when only" rules — replaced by smart_gaps/smart_borders
    #   the noctalia/swaync layerrules — those shells are gone
  };
}
