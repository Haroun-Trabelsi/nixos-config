{ host, ... }:
{
  programs.hyprlock = {
    enable = true;

    settings = {
      general = {
        hide_cursor = true;
        ignore_empty_input = true;
        fractional_scaling = 0;
      };

      background = [
        {
          path = "${../../../wallpapers/otherWallpaper/gruvbox/forest_road.jpg}";

          color = "rgba(36, 39, 58, 255)";
          blur_passes = 2;
          vibrancy_darkness = 0.0;
        }
      ];

      shape = [
        # User box
        {
          size = "300, 50";

          rounding = 0;
          border_size = 2;
          color = "rgba(54, 58, 79, 0.33)";
          border_color = "rgba(110, 115, 141, 0.95)";

          position = "0, 270";
          halign = "center";
          valign = "bottom";
        }
      ];

      label = [
        # Time
        {
          text = ''cmd[update:1000] echo "$(date +'%k:%M')"'';

          font_size = 115;
          font_family = "JetBrains Mono";

          shadow_passes = 3;
          color = "rgba(202, 211, 245, 0.9)";

          position = "0, -150";
          halign = "center";
          valign = "top";
        }
        # Date
        {
          text = ''cmd[update:1000] echo "- $(date +'%A, %B %d') -" '';

          font_size = 18;
          font_family = "JetBrains Mono";

          shadow_passes = 3;
          color = "rgba(202, 211, 245, 0.9)";

          position = "0, -350";
          halign = "center";
          valign = "top";
        }
        # Username
        {
          text = "  $USER";

          font_size = 15;
          font_family = "JetBrains Mono";

          color = "rgba(202, 211, 245, 1)";

          position = "0, 284";
          halign = "center";
          valign = "bottom";
        }
      ];

      input-field = [
        {
          size = "300, 50";
          rounding = 0;
          outline_thickness = 2;

          dots_spacing = 0.4;

          font_color = "rgba(202, 211, 245, 0.9)";
          font_family = "JetBrains Mono";

          outer_color = "rgba(110, 115, 141, 0.95)";
          inner_color = "rgba(54, 58, 79, 0.33)";
          check_color = "rgba(166, 218, 149, 0.95)";
          fail_color = "rgba(237, 135, 150, 0.95)";
          capslock_color = "rgba(238, 212, 159, 0.95)";
          bothlock_color = "rgba(238, 212, 159, 0.95)";

          hide_input = false;
          fade_on_empty = false;
          placeholder_text = ''<i><span foreground="##cad3f5">Enter Password</span></i>'';

          position = "0, 200";
          halign = "center";
          valign = "bottom";
        }
      ];

      animation = [ "inputFieldColors, 0" ];
    };
  };
}
