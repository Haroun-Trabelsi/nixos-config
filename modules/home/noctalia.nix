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

        # Gap between adjacent widgets. Default is 6; this is a nudge, not a
        # redesign — enough to stop the bar reading as one run-on block.
        widget_spacing = 8;

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
          "weather"
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
          "davemhammer/obsidian:status"
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
      # bongocat watches nothing by default: its input_devices setting is
      # declared `default = []` and the Luau does no auto-detection, so the cat
      # draws and never animates.
      #
      # THE KEY IS [widget."<widget id>"], not [plugin_settings."<plugin id>"].
      # Both tables exist and both feed plugin settings, but they are not
      # interchangeable — from src/shell/bar/widget_factory.cpp:
      #
      #     overrides = wc->settings;                  // the [widget.*] table
      #     seeded    = seedEntrySettings(entry, overrides);
      #     mergePluginSettings(manifest, plugin_settings[id], seeded);
      #
      # and mergePluginSettings skips any key already in `seeded`
      # ("entry-level setting declared the same key — entry wins").
      # input_devices is declared under [[widget.setting]] WITH a default, so
      # seedEntrySettings always fills it and the plugin_settings table can
      # never override it. Only [widget.*] reaches it.
      #
      # checkConfig accepts either spelling, so a green build proves nothing
      # here — the evidence is whether an `evtest` child appears under noctalia.
      #
      # A glob, not a device path: this tower has four *-event-kbd nodes and the
      # plugin's own comment warns that event numbers move between boots. It
      # also makes the same line work on the laptop.
      widget."noctalia/bongocat:cat".input_devices = [
        "/dev/input/by-path/*-event-kbd"
      ];

      # The obsidian plugin's vault_path goes in the OTHER table, and the reason
      # is the merge order quoted above rather than inconsistency:
      #
      #   seedEntrySettings  iterates entry.settings  — the [[widget.setting]] block
      #   mergePluginSettings iterates manifest.settings — the [[setting]] block,
      #                       skipping any key seedEntrySettings already filled
      #
      # bongocat declares input_devices as a [[widget.setting]], so it is always
      # seeded and only [widget.*] can reach it. obsidian declares vault_path as
      # a top-level [[setting]] and its status widget declares only show_dirty —
      # so vault_path is never seeded, and [plugin_settings.*] is what reaches
      # it. Using [widget.*] here would silently do nothing.
      #
      # plugin_settings is keyed by PLUGIN id, with no ":entry" suffix. It also
      # feeds the service entry (plugin_service_host.cpp does the same seed-then-
      # merge), which is the half that actually polls git.
      #
      # The default is ~/Documents/Obsidian Vault, which does not exist here.
      # The vault root is the directory holding .obsidian, so it is notes/ and
      # not its parent. vault_name is left empty on purpose: empty means "use the
      # folder name", and "notes" is what Obsidian itself registered the vault
      # as, so obsidian:// URIs resolve.
      plugin_settings."davemhammer/obsidian".vault_path = "${config.home.homeDirectory}/vault/notes";

      # nix-monitor's action buttons. Same [plugin_settings.*] reasoning as
      # above: both of these are top-level [[setting]] keys, not widget ones.
      plugin_settings."avivbintangaringga/nix-monitor" = {
        # update_command defaults to "" and panel.luau refuses to run an empty
        # one ("update command is empty"), so the Update button is dead until
        # this is set. The widget compares LOCAL vs REMOTE nixpkgs revision, so
        # the matching action is update-then-switch rather than switch alone —
        # this is the `nfu` alias from zsh_alias.nix spelled out, because the
        # plugin runs the string in a terminal that never sources zsh aliases.
        #
        # nixpkgs AND home-manager, never nixpkgs alone. home-manager's input
        # is `inputs.nixpkgs.follows = "nixpkgs"`, so bumping nixpkgs by itself
        # drags a home-manager that was written against the OLD nixpkgs onto
        # the new one. That is not theoretical: it broke eval outright on
        # 2026-09-15, when nixpkgs changed neovim's userPluginViml from a list
        # to `nullOr lines` and a seven-month-old home-manager still did
        # `concatStringsSep "\n"` over it — "expected a list but found null",
        # from a nvim.nix that sets four options and no plugins.
        # nh needs no flake path: programs.nh.flake is set in modules/core/nh.nix.
        update_command = "nix flake update --flake ${config.home.homeDirectory}/nixos-config nixpkgs home-manager && nh-notify nh os switch";

        # NOT the plugin default of `nix-collect-garbage -d`, which deletes
        # every old generation. modules/core/nh.nix deliberately keeps 5 and
        # everything from the last week so the boot-menu rollback path always
        # has something to roll back TO — one click of a -d button throws
        # exactly that away. Same retention as nh.clean.extraArgs.
        clean_command = "nh clean all --keep-since 7d --keep 5";
      };

      # Forces software (libx264) encoding instead of the plugin's own default
      # of GPU/NVENC. On this card (RTX 5060 Ti, driver 595.99.02) NVENC itself
      # is broken for every codec right now, not just h264 — gpu-screen-recorder
      # logs "your nvidia driver only supports nvenc api version 13.0, but the
      # FFmpeg version that GPU Screen Recorder uses requires nvenc api version
      # 13.1", so recordings ended instantly with no output file. Confirmed by
      # hand: `gpu-screen-recorder -w portal -k hevc ...` hits the same 13.0
      # vs 13.1 mismatch (falls back to h264, which then fails too); `-encoder
      # cpu` produced a real file. Revisit once nixpkgs' gpu-screen-recorder or
      # the nvidia driver closes that API gap — this is a version-skew bug, not
      # a permanent hardware limitation.
      plugin_settings."noctalia/screen_recorder".video_encoder = "cpu";

      # was location.name. [location] is the single "where am I", feeding
      # weather, night light and theme auto mode — geocoded because
      # auto_locate is left off (no IP lookup).
      location.address = "Menzel Bou Zelfa, Tunisia";

      # Weather defaults to enabled = false, so the bar's "weather" widget
      # renders nothing until this is set — having [location] is not enough,
      # which is what made the widget look broken rather than off.
      weather = {
        enabled = true;
        unit = "celsius";
      };

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
