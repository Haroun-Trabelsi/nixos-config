{
  config,
  osConfig,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  pluginSourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";

  # Plugins to install and enable. Each must be a directory in
  # inputs.noctalia-plugins containing a manifest.json.
  enabledPlugins = [
    "slowbongo" # bongo cat in the bar, slaps when you type
    "screen-recorder" # official; hardware-accelerated via gpu-screen-recorder
    "update-count" # taught about Nix via pluginSettings below
  ];
in
{
  programs.noctalia-shell = {
    # desktop shell
    enable = osConfig.machine.profile == "desktop";

    # systemd crashes before Wayland is ready — launch from hyprland exec-once instead
    systemd.enable = false;

    # ── Shell settings ──────────────────────────────────────────────
    # Written to ~/.config/noctalia/settings.json
    # Tip: run `noctalia-shell ipc call state all | jq .settings`
    #      to dump live settings after tweaking via the GUI,
    #      then paste them here for a permanent declarative config.
    settings = {

      # ── Bar ─────────────────────────────────────────────────────
      bar = {
        position = "top"; # TEST: moved from top to bottom
        # barType = "simple";
        # density = "default"; # "default" | "compact" | "spacious"
        # showCapsule = true;
        # capsuleOpacity = 1;
        backgroundOpacity = 0; # fully transparent bar background
        marginVertical = 10; # TEST: bumped from 4 to 10
        marginHorizontal = 10; # TEST: bumped from 4 to 10
        frameRadius = 24; # TEST: doubled from 12 to 24
        # outerCorners = true;
        # displayMode = "always_visible"; # "always_visible" | "auto_hide"
        mouseWheelAction = "workspace"; # scroll bar to switch workspaces
        # rightClickAction = "controlCenter";
        # Declared in full, because a plugin's bar widget does NOT appear on its
        # own here.
        #
        # noctalia only auto-places a widget in the code path that DOWNLOADS a
        # plugin (PluginService.qml calls addWidgetToBar right after the git
        # clone succeeds). These plugins are placed from the store instead, so
        # the files are already present, that path never runs, and the widget is
        # installed and enabled but shown nowhere.
        #
        # It cannot be fixed from the UI either: settings.json is a read-only
        # symlink into the store because this block manages it, so dragging a
        # widget onto the bar has nothing to save to. The layout has to be here.
        #
        # These are noctalia's own defaults (Commons/Settings.qml) plus the three
        # plugin widgets. Plugin widget ids are "plugin:" + the plugin id — plain,
        # not hashed, because the source is the main registry
        # (PluginRegistry.generateCompositeKey returns the bare id for it).
        widgets = {
          left = [
            { id = "Launcher"; }
            { id = "Clock"; }
            { id = "SystemMonitor"; }
            { id = "ActiveWindow"; }
            { id = "MediaMini"; }
            # Reacts to typing, so it belongs near where text happens.
            { id = "plugin:slowbongo"; }
          ];
          center = [ { id = "Workspace"; } ];
          right = [
            { id = "plugin:update-count"; }
            { id = "plugin:screen-recorder"; }
            { id = "Tray"; }
            { id = "NotificationHistory"; }
            { id = "Battery"; }
            { id = "Volume"; }
            { id = "Brightness"; }
            { id = "ControlCenter"; }
          ];
        };
      };

      # ── General ─────────────────────────────────────────────────
      general = {
        # avatarImage = "";

        # animationSpeed is a DIVISOR of every duration in Commons/Style.qml:
        #   animationNormal = round(300 / animationSpeed)  (ms)
        # so HIGHER = FASTER, not slower. The old value of 2 was committed as
        # "slowed from 1 to 2" and did the exact opposite: 300/2 = 150 ms, i.e.
        # double speed, which is why the shell barely looked animated at all.
        # 1 is upstream's default (300 ms). Drop to 0.5 for genuinely slower,
        # more visible motion (600 ms); the settings GUI shows this as a
        # percentage, so 1 reads as "100%".
        animationSpeed = 1;

        # Explicit, not implicit: this is the master switch, and both it and
        # noctaliaPerformance mode short-circuit every duration to 0.
        animationDisabled = false;

        # Was off, so the lock screen appeared/dismissed as a hard cut while
        # the rest of the shell animated. On for consistency.
        lockScreenAnimations = true;

        # enableShadows = true;
        # enableBlurBehind = true;
        # lockOnSuspend = true;
        # showSessionButtonsOnLockScreen = true;
        # telemetryEnabled = false;
      };

      # ── UI ──────────────────────────────────────────────────────
      ui = {
        # fontDefault = "";
        # fontFixed = "";
        # fontDefaultScale = 1;
        # fontFixedScale = 1;
        # tooltipsEnabled = true;
        # panelBackgroundOpacity = 0.93;
        # panelsAttachedToBar = true;
      };

      # ── Location & Weather ──────────────────────────────────────
      location = {
        name = "Menzel Bou Zelfa, Tunisia";
        # weatherEnabled = true;
        # useFahrenheit = false;
        # use12hourFormat = false;
        # showWeekNumberInCalendar = false;
        # firstDayOfWeek = -1; # -1 = locale default, 0 = Sunday, 1 = Monday
      };

      # ── App Launcher ────────────────────────────────────────────
      appLauncher = {
        # position = "center"; # "center" | "top" | "bottom"
        terminalCommand = "kitty -e";
        sortByMostUsed = true;
        # viewMode = "list"; # "list" | "grid"
        enableClipboardHistory = true;
        enableSettingsSearch = true;
        enableWindowsSearch = true;
      };

      # ── Wallpaper ───────────────────────────────────────────────
      # The directory was previously left undeclared, so noctalia fell back to
      # its built-in default of ~/Pictures/Wallpapers. Same path, but stated
      # here so it is a decision rather than a coincidence.
      #
      # wallpaper.nix installs assets/wallpapers/wallpaper.jpg into this
      # directory. Note noctalia CANNOT persist a wallpaper choice back to
      # settings.json (home-manager owns it as a read-only store symlink) — it
      # remembers the current pick in ~/.cache/noctalia/wallpapers.json instead.
      wallpaper = {
        enabled = true;
        directory = "${config.home.homeDirectory}/Pictures/Wallpapers";
        # 3840x2160 source on a 1920x1080 primary and a 1080p TV: crop rather
        # than stretch, and paint both outputs.
        fillMode = "crop";
        setWallpaperOnAllMonitors = true;
        # No slideshow: one wallpaper, deliberately.
        automationEnabled = false;
      };

      # ── Control Center ──────────────────────────────────────────
      # controlCenter = {
      #   position = "close_to_bar_button";
      #   shortcuts = {
      #     left = [
      #       { id = "Network"; }
      #       { id = "Bluetooth"; }
      #       { id = "WallpaperSelector"; }
      #       { id = "NoctaliaPerformance"; }
      #     ];
      #     right = [
      #       { id = "Notifications"; }
      #       { id = "PowerProfile"; }
      #       { id = "KeepAwake"; }
      #       { id = "NightLight"; }
      #     ];
      #   };
      # };

      # ── Dock ────────────────────────────────────────────────────
      dock = {
        # enabled = true;
        # position = "bottom"; # "top" | "bottom" | "left" | "right"
        # displayMode = "auto_hide"; # "auto_hide" | "always_visible" | "intellihide"
        # dockType = "floating"; # "floating" | "panel"
        # pinnedApps = [];
        # groupApps = false;
        # animationSpeed = 1;
      };

      # ── Notifications ───────────────────────────────────────────
      notifications = {
        # enabled = true;
        # location = "top_right";
        # lowUrgencyDuration = 3;
        # normalUrgencyDuration = 8;
        # criticalUrgencyDuration = 15;
        # sounds.enabled = false;
        # enableBatteryToast = true;
      };

      # ── OSD (on-screen display) ─────────────────────────────────
      # osd = {
      #   enabled = true;
      #   location = "top_right";
      #   autoHideMs = 2000;
      # };

      # ── Audio / Media ───────────────────────────────────────────
      audio = {
        # volumeStep = 5;
        # volumeOverdrive = false;
        preferredPlayer = "spotify";
        # visualizerType = "linear"; # "linear" | "circular"
      };

      # ── Brightness ──────────────────────────────────────────────
      brightness = {
        # brightnessStep = 5;
        enableDdcSupport = true;
      };

      # ── Color Scheme ────────────────────────────────────────────
      colorSchemes = {
        predefinedScheme = "Eldritch";
        # useWallpaperColors = false;
        # darkMode = true;
        # schedulingMode = "off"; # "off" | "manual" | "auto"
        # generationMethod = "tonal-spot";
        # syncGsettings = true;
      };

      # ── Templates (auto-theme installed programs) ──────────────
      templates = {
        enableUserTheming = true;
        activeTemplates = [
          "kitty" # terminal colors
          "btop" # system monitor theme
          "code" # vscode editor theme
          "discord" # vesktop midnight + material css
          "spicetify" # spotify catppuccin theme colors
          "hyprland" # compositor border/accent colors
          "gtk" # gtk3 + gtk4 theming
          "qt" # qt5ct + qt6ct color scheme
          "kcolorscheme" # kde color scheme (dolphin etc)
          "steam" # steam material theme css
        ];
      };

      # ── Idle ────────────────────────────────────────────────────
      idle = {
        # enabled = false;
        # screenOffTimeout = 600;
        # lockTimeout = 660;
        # suspendTimeout = 1800;
        # lockCommand = "";
        # suspendCommand = "";
      };

      # ── Session Menu ────────────────────────────────────────────
      # sessionMenu = {
      #   enableCountdown = true;
      #   position = "center";
      #   showKeybinds = true;
      # };

      # ── Night Light ─────────────────────────────────────────────
      # nightLight = {
      #   enabled = false;
      #   nightTemp = "4000";
      #   dayTemp = "6500";
      # };

      # ── Hooks (run shell commands on events) ────────────────────
      # hooks = {
      #   enabled = false;
      #   wallpaperChange = "";
      #   darkModeChange = "";
      #   screenLock = "";
      #   screenUnlock = "";
      #   startup = "";
      # };

      # ── Desktop Widgets ─────────────────────────────────────────
      # desktopWidgets = {
      #   enabled = false;
      # };
    };

    # ── Color scheme (Material 3) ─────────────────────────────────
    # Written to ~/.config/noctalia/colors.json — overrides predefinedScheme
    # on startup, so values must match the active scheme. Eldritch palette
    # mirrored from noctalia's Assets/ColorScheme/Eldritch/Eldritch.json.
    colors = {
      dark = {
        mPrimary = "#37f499";
        mOnPrimary = "#171928";
        mSecondary = "#04d1f9";
        mOnSecondary = "#171928";
        mTertiary = "#a48cf2";
        mOnTertiary = "#171928";
        mError = "#f16c75";
        mOnError = "#171928";
        mSurface = "#212337";
        mOnSurface = "#ebfafa";
        mSurfaceVariant = "#292e42";
        mOnSurfaceVariant = "#ABB4DA";
        mOutline = "#3b4261";
        mShadow = "#414868";
        mHover = "#a48cf2";
        mOnHover = "#171928";
      };
      light = {
        mPrimary = "#37f499";
        mOnPrimary = "#171928";
        mSecondary = "#04d1f9";
        mOnSecondary = "#171928";
        mTertiary = "#a48cf2";
        mOnTertiary = "#171928";
        mError = "#f16c75";
        mOnError = "#171928";
        mSurface = "#ffffff";
        mOnSurface = "#171928";
        mSurfaceVariant = "#f2f4f8";
        mOnSurfaceVariant = "#3b4261";
        mOutline = "#3b4261";
        mShadow = "#414868";
        mHover = "#a48cf2";
        mOnHover = "#171928";
      };
    };

    # ── User templates (application theming) ──────────────────────
    # Written to ~/.config/noctalia/user-templates.toml
    # Use this to auto-generate theme files for other apps when
    # the color scheme changes.
    # user-templates = {};

    # ── Plugins ───────────────────────────────────────────────────
    # Written to ~/.config/noctalia/plugins.json. This marks plugins ENABLED;
    # the code itself is placed below from the pinned inputs.noctalia-plugins,
    # so noctalia never reaches the network for it.
    plugins = {
      version = 2;
      sources = [
        {
          enabled = true;
          name = "Noctalia Plugins";
          url = pluginSourceUrl;
        }
      ];
      states = lib.genAttrs enabledPlugins (_: {
        enabled = true;
        sourceUrl = pluginSourceUrl;
      });
    };

    # ── Per-plugin settings ───────────────────────────────────────
    # Each key becomes ~/.config/noctalia/plugins/<name>/settings.json
    pluginSettings = {
      # update-count ships with pacman/apt/dnf detection and no idea what Nix
      # is. It does support a CUSTOM updater, which is the hook used here.
      #
      # "Number of updates" does not mean the same thing on NixOS: there is no
      # per-package upgrade list, there is one input revision everything follows.
      # nix-update-count reports 1 when the flake's locked nixpkgs differs from
      # the current nixos-unstable channel revision, 0 when it matches — see
      # scripts/scripts/nix-update-count.sh for why that is the honest answer.
      update-count = {
        customCmdGetNumUpdates = "nix-update-count";
        # `nh os switch` rather than a bare nixos-rebuild: it is what this config
        # uses everywhere else, and programs.nh.flake already points at the repo.
        customCmdDoSystemUpdate = "nix flake update --flake $HOME/nixos-config && nh os switch";
        updateIntervalMinutes = 180;
        updateTerminalCommand = "kitty -e";
        hideOnZero = true;
      };
    };
  };

  # ── Plugin code, pinned ─────────────────────────────────────────────────
  # noctalia installs plugins by `git clone`-ing the registry repo at runtime
  # (Services/Noctalia/PluginService.qml). That would make the bar's widgets
  # whatever was on main the day they happened to be installed, recorded
  # nowhere. These come from inputs.noctalia-plugins instead, so they are in
  # flake.lock like everything else.
  #
  # `recursive = true` matters: it symlinks each FILE rather than the directory,
  # leaving ~/.config/noctalia/plugins/<id>/ itself writable. The plugin dir is
  # also where a plugin's own settings.json lives, and a read-only store symlink
  # for the directory would make that unwritable — the same trap that bit
  # ~/.ssh/config and ~/.tmux.conf.local in this config.
  xdg.configFile = lib.mkIf (osConfig.machine.profile == "desktop") (
    lib.genAttrs (map (id: "noctalia/plugins/${id}") enabledPlugins) (name: {
      source = "${inputs.noctalia-plugins}/${lib.removePrefix "noctalia/plugins/" name}";
      recursive = true;
    })
  );

  # gpu-screen-recorder is what the screen-recorder plugin drives; without it the
  # widget loads and every recording fails. wl-clipboard/grim etc. are already in
  # modules/home/wayland-tools.nix.
  home.packages = lib.mkIf (osConfig.machine.profile == "desktop") [
    pkgs.gpu-screen-recorder
  ];
}
