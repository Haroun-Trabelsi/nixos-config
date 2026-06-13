{ ... }:
{
  programs.noctalia-shell = {
    enable = true;

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
        # widgets = {
        #   left = [
        #     { id = "Launcher"; }
        #     { id = "Clock"; }
        #     { id = "SystemMonitor"; }
        #     { id = "ActiveWindow"; }
        #     { id = "MediaMini"; }
        #   ];
        #   center = [
        #     { id = "Workspace"; }
        #   ];
        #   right = [
        #     { id = "Tray"; }
        #     { id = "NotificationHistory"; }
        #     { id = "Battery"; }
        #     { id = "Volume"; }
        #     { id = "Brightness"; }
        #     { id = "ControlCenter"; }
        #   ];
        # };
      };

      # ── General ─────────────────────────────────────────────────
      general = {
        # avatarImage = "";
        animationSpeed = 2; # TEST: slowed from 1 to 2
        # animationDisabled = false;
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

      # ── Noctalia Performance ──────────────────────────────────────
      # Enabled by default via exec-once IPC call.
      noctaliaPerformance = {
        disableWallpaper = false;
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
    # Written to ~/.config/noctalia/plugins.json
    # plugins = {};

    # ── Per-plugin settings ───────────────────────────────────────
    # Each key becomes ~/.config/noctalia/plugins/<name>/settings.json
    # pluginSettings = {};
  };
}
