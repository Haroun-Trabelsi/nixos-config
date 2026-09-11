{
  config,
  osConfig,
  lib,
  ...
}:
# Noctalia 5.x — the desktop shell on the tower.
#
# MIGRATED from 4.7.7, which was not a version bump: 4.x was QML on
# Quickshell/Qt, 5.x is native C++ on Wayland + OpenGL ES with no Qt or GTK.
# Consequences that shaped this file:
#
#   * programs.noctalia-shell -> programs.noctalia
#   * settings.json -> config.toml, with a different schema throughout
#     (bar.backgroundOpacity -> bar.main.background_opacity, and so on)
#   * the module lost its `colors`, `user-templates`, `plugins` and
#     `pluginSettings` options. Palettes are `customPalettes`; the Eldritch
#     scheme this config uses is now a BUILT-IN (theme.builtin = "Eldritch"),
#     so modules/home/theme.nix no longer has to feed it a colour list.
#   * plugins went from QML + manifest.json to Luau + plugin.toml, so the three
#     community plugins that were here (slowbongo, screen-recorder,
#     update-count) do not load any more. Their official replacements are wired
#     up in modules/home/noctalia-plugins.nix.
#
# `checkConfig` defaults to true and validates config.toml at BUILD time, which
# is what makes this safe to change: a bad key fails the build rather than
# leaving the tower with no bar.
{
  programs.noctalia = {
    enable = osConfig.machine.profile == "desktop";

    settings = {
      shell = {
        settings_show_advanced = true;
        # Was appLauncher.enableClipboardHistory.
        clipboard_enabled = true;

        animation = {
          enabled = true; # was general.animationDisabled = false
          speed = 1.0; # was general.animationSpeed = 1
        };

        launcher = {
          sort_by_usage = true; # was appLauncher.sortByMostUsed
        };
      };

      bar.main = {
        position = "top";
        background_opacity = 0.0; # fully transparent bar background
        radius = 24; # was frameRadius
        margin_edge = 10; # was marginVertical
        margin_ends = 10; # was marginHorizontal

        # Widget ids are all renamed in 5.x: lowercase and kebab-case, and the
        # left/center/right keys are start/center/end.
        #   Launcher -> launcher              MediaMini    -> media
        #   Clock -> clock                    Workspace    -> workspaces
        #   SystemMonitor -> sysmon           Tray         -> tray
        #   ActiveWindow -> active_window     ControlCenter-> control-center
        #   NotificationHistory -> notifications
        #
        # Note the inconsistency, which is not a typo here: most ids use
        # UNDERSCORES (active_window, theme_mode, power_profile) but
        # control-center uses a hyphen. Taken from the authoritative list in
        # src/shell/bar/widget_factory.cpp, after the shell logged
        # `widget factory: unknown widget "active-window"` for the hyphenated
        # guess.
        #
        # Plugin widgets are "author/plugin:entry" — see noctalia-plugins.nix.
        start = [
          "launcher"
          "clock"
          "sysmon"
          "active_window"
          "media"
          "noctalia/bongocat:cat" # reacts to typing, so it sits near the text
        ];
        center = [ "workspaces" ];
        end = [
          "noctalia/screen_recorder:recorder"
          "tray"
          "notifications"
          "battery"
          "volume"
          "brightness"
          "control-center"
        ];
      };

      # was location.name
      location.address = "Menzel Bou Zelfa, Tunisia";

      wallpaper = {
        enabled = true;
        directory = "${config.home.homeDirectory}/Pictures/Wallpapers";
        fill_mode = "crop"; # was fillMode
      };

      # was brightness.enableDdcSupport. The tower drives external monitors over
      # DDC/CI; machines/desktop/peripherals.nix provides ddcutil and the i2c
      # group membership it needs.
      brightness.enable_ddcutil = true;

      # was colorSchemes.predefinedScheme = "Eldritch". Eldritch ships as a
      # built-in scheme in 5.x, so this no longer needs a hand-written palette.
      theme = {
        mode = "dark";
        source = "builtin";
        builtin = "Eldritch";
      };
    };
  };
}
