{ pkgs, config, osConfig, ... }:
let
  c = config.theme.colors;
in
{
  # swaybar rather than waybar, deliberately. swaybar is a small wlroots client
  # built into sway with native StatusNotifierItem tray support, so nm-applet,
  # blueman and udiskie keep their tray icons. waybar is a GTK3 app with a CSS
  # engine and its own redraw loop — more idle wakeups for the same information.
  wayland.windowManager.sway.config.bars = [
    {
      position = "top";
      statusCommand = "${pkgs.i3status-rust}/bin/i3status-rs ~/.config/i3status-rust/config-default.toml";
      fonts = {
        names = [ "JetBrainsMono Nerd Font" ];
        size = 11.0;
      };
      trayOutput = "primary";
      colors = {
        background = c.mantle;
        statusline = c.text;
        separator = c.overlay;
        focusedWorkspace = {
          border = c.tertiary;
          background = c.tertiary;
          text = c.inverse;
        };
        activeWorkspace = {
          border = c.surface;
          background = c.surface;
          text = c.text;
        };
        inactiveWorkspace = {
          border = c.mantle;
          background = c.mantle;
          text = c.subtext;
        };
        urgentWorkspace = {
          border = c.error;
          background = c.error;
          text = c.inverse;
        };
      };
    }
  ];

  programs.i3status-rust = {
    # swaybar/i3status-rust is the laptop bar; noctalia provides the desktop bar
    enable = osConfig.machine.profile == "laptop";
    bars.default = {
      theme = "native"; # colours come from swaybar above
      icons = "awesome6";
      # 5 s rather than the 1 s default: a per-second tick is a per-second
      # wakeup on a machine whose whole point is reaching deep C-states.
      settings.theme.overrides = {
        idle_bg = c.mantle;
        idle_fg = c.text;
        good_fg = c.primary;
        warning_fg = c.warning;
        critical_fg = c.error;
        separator = "";
      };
      blocks = [
        {
          block = "disk_space";
          path = "/";
          info_type = "available";
          format = " $icon $available ";
          alert = 10.0;
          warning = 20.0;
        }
        {
          block = "memory";
          format = " $icon $mem_used_percents ";
          interval = 10;
        }
        {
          block = "cpu";
          format = " $icon $utilization ";
          interval = 5;
        }
        {
          block = "temperature";
          format = " $icon $max ";
          interval = 10;
          good = 40;
          idle = 55;
          warning = 75;
        }
        {
          # The number that matters for this whole project — and deliberately NOT
          # the built-in `battery` block, which reads power_now. On this ASUS EC
          # power_now is a computed estimate that swings 3-18 W at random and
          # reports "Charging" while the pack is draining (measured: 25 min of
          # "Charging" during which it fell 77% -> 70%, a real -5.77 W).
          #
          # battery-net differences energy_now instead, so the sign is truthful.
          # It turns Warning when a charger is attached but the battery is STILL
          # losing charge — the exact condition power_now hides.
          block = "custom";
          command = "battery-net";
          json = true;
          interval = 30;
        }
        {
          block = "sound";
          format = " $icon $volume ";
        }
        {
          block = "time";
          format = " $icon $timestamp.datetime(f:'%a %d/%m %R') ";
          interval = 30;
        }
      ];
    };
  };
}
