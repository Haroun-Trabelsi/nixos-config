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
        # NOT transparent any more. The bar sits at the top, and the top of
        # assets/wallpapers/wallpaper.jpg is its lightest region — pale cyan sky
        # across most of the width, with blossom only at the right edge.
        # Measured against that strip, Eldritch's #ebfafa text on the bare
        # wallpaper gives:
        #
        #     pale sky        1.28:1     <- effectively invisible
        #     strip average   1.86:1
        #     purple blossom  6.02:1     <- the only readable part
        #
        # WCAG AA wants 4.5:1 for normal text. Blending the Eldritch base
        # (#212337) behind it at this opacity gives 5.66:1, which passes while
        # still letting the wallpaper through. 0.95 gives 9.51:1 and 1.0 gives
        # 14.40:1 if you would rather have contrast than translucency.
        #
        # The palette was never the problem — a fully transparent bar means the
        # background is whatever the wallpaper happens to be, and no single text
        # colour works against both a pale sky and a dark tree.
        background_opacity = 0.85;
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
          # Nixpkgs update status: click for local vs remote revision, NixOS and
          # home-manager generations, store size. Replaces the update-count
          # workaround that was here under 4.x, which had no idea what Nix was.
          "avivbintangaringga/nix-monitor:nix-monitor"
          "noctalia/screen_recorder:recorder"
          "tray"
          "notifications"
          "battery"
          "volume"
          "brightness"
          "control-center"
        ];
      };

      # Per-widget settings. The bongocat plugin watches nothing by default —
      # its input_devices setting is declared with `default = []` and the Luau
      # does no auto-detection, so out of the box the cat simply never moves.
      #
      # A glob rather than a fixed path: this tower has four *-event-kbd nodes
      # and event numbers are not stable across boots, which is exactly what the
      # plugin's own comment warns about ("Prefer stable by-id/by-path entries
      # over /dev/input/eventN because event numbers can change"). Matching all
      # keyboards by path also means the same line works on the laptop.
      # NOTE the key: plugin_settings, keyed by PLUGIN id
      # ("noctalia/bongocat"), not widget id ("noctalia/bongocat:cat") and not
      # the [widget.*] table that built-in widgets use. From
      # src/config/config_export.cpp, which writes
      # root.insert_or_assign("plugin_settings", ...) over a map the header
      # documents as "keyed by plugin id then setting key".
      #
      # Worth knowing: checkConfig accepted the wrong key without complaint, so
      # a build passing is not evidence that a setting is being read.
      plugin_settings."noctalia/bongocat".input_devices = [
        "/dev/input/by-path/*-event-kbd"
      ];

      # was location.name
      location.address = "Menzel Bou Zelfa, Tunisia";

      wallpaper = {
        enabled = true;
        directory = "${config.home.homeDirectory}/Pictures/Wallpapers";
        fill_mode = "crop"; # was fillMode

        # The wallpaper, pinned. Without this noctalia picks for itself — on the
        # first 5.x start it set its own bundled asset out of the package's
        # share/noctalia/assets.
        #
        # This is modules/home/wallpaper.nix's vendored file, reached through the
        # stable ~/Pictures path rather than the store path it resolves to, so
        # the value does not churn on every rebuild.
        #
        # CAVEAT worth knowing: runtime state OUTRANKS this. noctalia's own
        # tests/config_wallpaper_precedence_test.cpp asserts "sidecar path did
        # not win once set" — ~/.local/state/noctalia/settings.toml is read
        # last. So this is the default for fresh state, and picking a different
        # wallpaper in the UI still wins, which is the behaviour you want. To
        # force this one back, delete the [wallpaper.*] tables from that file,
        # or run: noctalia msg wallpaper-set <path>
        default.path = "${config.home.homeDirectory}/Pictures/Wallpapers/wallpaper.jpg";

        # Never rotate. The directory above holds more than one image, and the
        # point of vendoring a wallpaper into the repo was that the desktop
        # looks the same on both machines and after a reinstall.
        automation.enabled = false;
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
