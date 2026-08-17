{ ... }:
let
  mod = "Mod4";

  # Directional movement, bound on both arrows and hjkl.
  dirs = {
    left = "left";
    right = "right";
    up = "up";
    down = "down";
    h = "left";
    l = "right";
    k = "up";
    j = "down";
  };
  forEachDir = f: builtins.listToAttrs (map f (builtins.attrNames dirs));
in
{
  wayland.windowManager.sway.config = {
    keybindings =
      {
        "${mod}+F1" = "exec show-keybinds";

        # --- launching ---
        "${mod}+Return" = "exec ghostty --gtk-single-instance=true";
        # Hyprland could attach window rules to an exec; sway cannot, so the
        # floating variant launches with its own app_id and rules.nix matches it.
        "Alt+Return" = "exec ghostty --gtk-single-instance=false --class=ghostty-float";
        "${mod}+Shift+Return" = "exec ghostty --gtk-single-instance=false --class=ghostty-full";
        "${mod}+t" = "exec kitty";
        "${mod}+e" = "exec dolphin";
        "Alt+e" = "exec dolphin --qwindowgeometry 1111x700";
        "${mod}+b" = "exec toggle-browser";
        "${mod}+d" = "exec toggle-discord";
        "${mod}+s" = "exec toggle-music";
        "${mod}+g" = "exec toggle-github-desktop";
        "${mod}+c" = "exec work-terminals";
        "${mod}+n" = "exec pavucontrol";
        "${mod}+Shift+p" = "exec linear-plan";
        "Ctrl+Shift+Escape" = "exec missioncenter";

        # --- window management ---
        "${mod}+q" = "kill";
        "${mod}+f" = "fullscreen toggle";
        "${mod}+Shift+f" = "fullscreen toggle global";
        "${mod}+space" = "exec toggle-float";
        "${mod}+a" = "sticky toggle"; # was `pin`
        "${mod}+p" = "layout toggle split"; # closest thing to `pseudo`
        "${mod}+Tab" = "workspace back_and_forth";
        "${mod}+Ctrl+c" = "exec move-to-empty-workspace";

        "Ctrl+Alt+Up" = "focus mode_toggle";
        "Ctrl+Alt+Down" = "focus mode_toggle";

        # --- shell features (were noctalia IPC calls) ---
        "${mod}+Shift+d" = "exec fuzzel";
        "${mod}+v" = "exec clipboard-picker";
        "${mod}+w" = "exec makoctl restore";
        "${mod}+Shift+n" = "exec toggle-nightlight";
        "${mod}+Escape" = "exec swaylock -f";
        "${mod}+Shift+Escape" = "exec power-menu";
        "${mod}+Shift+b" = "bar mode toggle";

        # --- capture ---
        "Print" = "exec screenshot --copy";
        "${mod}+Print" = "exec screenshot --save";
        "${mod}+Shift+Print" = "exec screenshot --swappy";
        "${mod}+Shift+s" = "exec screenshot --copy";
        "${mod}+Alt+r" = "exec screenrecord";
        "${mod}+Ctrl+o" = "exec ocr";

        # --- media ---
        "XF86AudioPlay" = "exec playerctl play-pause";
        "XF86AudioNext" = "exec playerctl next";
        "XF86AudioPrev" = "exec playerctl previous";
        "XF86AudioStop" = "exec playerctl stop";
        "${mod}+m" = "exec wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";

        # --- swayosd (moved here from modules/home/swayosd.nix) ---
        "XF86AudioMute" = "exec swayosd-client --output-volume mute-toggle";
        "XF86AudioMicMute" = "exec toggle-mic";
        "XF86AudioRaiseVolume" = "exec swayosd-client --output-volume +2";
        "XF86AudioLowerVolume" = "exec swayosd-client --output-volume -2";
        "${mod}+F11" = "exec swayosd-client --output-volume +2";
        "${mod}+F12" = "exec swayosd-client --output-volume -2";
        "XF86MonBrightnessUp" = "exec swayosd-client --brightness raise";
        "XF86MonBrightnessDown" = "exec swayosd-client --brightness lower";
        # --locked so they still work on the lock screen (Hyprland's bindl)
        "--locked ${mod}+XF86MonBrightnessUp" = "exec swayosd-client --brightness 100";
        "--locked ${mod}+XF86MonBrightnessDown" = "exec swayosd-client --brightness 0";
        # --release for lock keys (Hyprland's bindr)
        "--release Caps_Lock" = "exec swayosd-client --caps-lock";
        "--release Scroll_Lock" = "exec swayosd-client --scroll-lock";
        "--release Num_Lock" = "exec swayosd-client --num-lock";

        # --- mouse wheel over the bar/desktop switches workspace ---
        "--whole-window ${mod}+button4" = "workspace prev_on_output";
        "--whole-window ${mod}+button5" = "workspace next_on_output";
      }
      # focus / move / resize / reposition, on arrows and hjkl
      // forEachDir (k: {
        name = "${mod}+${k}";
        value = "focus ${dirs.${k}}";
      })
      // forEachDir (k: {
        name = "${mod}+Shift+${k}";
        value = "move ${dirs.${k}}";
      })
      // forEachDir (k: {
        name = "${mod}+Ctrl+${k}";
        value =
          let
            d = dirs.${k};
          in
          if d == "left" then
            "resize shrink width 80px"
          else if d == "right" then
            "resize grow width 80px"
          else if d == "up" then
            "resize shrink height 80px"
          else
            "resize grow height 80px";
      })
      // forEachDir (k: {
        name = "${mod}+Alt+${k}";
        value =
          let
            d = dirs.${k};
          in
          if d == "left" then
            "move left 80px"
          else if d == "right" then
            "move right 80px"
          else if d == "up" then
            "move up 80px"
          else
            "move down 80px";
      });

    # The AZERTY number row. Hyprland's `code:N` and sway's `bindcode N` are BOTH
    # X11 keycodes (evdev + 8), so this is a literal 1:1 port of the old binds.
    #
    # Do NOT be tempted to replace this with `bindsym --to-code $mod+1`:
    # --to-code resolves the symbol against the seat's first xkb layout, and in
    # `fr` the "1" symbol requires Shift, so it would generate Shift-requiring
    # binds. Keycodes sidestep the layout entirely.
    keycodebindings = builtins.listToAttrs (
      builtins.concatMap
        (i: [
          {
            name = "${mod}+${toString (i + 9)}";
            value = "workspace number ${toString i}";
          }
          {
            name = "${mod}+Shift+${toString (i + 9)}";
            # sway does not follow the window, matching `movetoworkspacesilent`
            value = "move container to workspace number ${toString i}";
          }
        ])
        [
          1
          2
          3
          4
          5
          6
          7
          8
          9
          10
        ]
    );
  };
}
