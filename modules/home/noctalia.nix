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

      # ── Wallpaper ───────────────────────────────────────────────
      # Disabled: mpvpaper drives the animated Hollow Knight wallpaper
      # instead (exec-once.nix). Noctalia only supports static images
      # and would conflict on the wlr background layer.
      wallpaper = {
        enabled = false;
        directory = "/home/fantasy/Pictures/Wallpapers";
        fillMode = "crop";
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
      # Enabled by default via exec-once IPC call; keep wallpaper running
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
        predefinedScheme = "Catppuccin";
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
    # Written to ~/.config/noctalia/colors.json
    # Catppuccin Macchiato palette — uncomment and tweak as desired.
    colors = {
      dark = {
        mPrimary = "#cba6f7";
        mOnPrimary = "#11111b";
        mSecondary = "#fab387";
        mOnSecondary = "#11111b";
        mTertiary = "#94e2d5";
        mOnTertiary = "#11111b";
        mError = "#f38ba8";
        mOnError = "#11111b";
        mSurface = "#1e1e2e";
        mOnSurface = "#cdd6f4";
        mSurfaceVariant = "#313244";
        mOnSurfaceVariant = "#a3b4eb";
        mOutline = "#4c4f69";
        mShadow = "#11111b";
        mHover = "#94e2d5";
        mOnHover = "#11111b";
        # terminal = {
        #   normal = {
        #     black = "#45475a"; red = "#f38ba8"; green = "#a6e3a1";
        #     yellow = "#f9e2af"; blue = "#89b4fa"; magenta = "#f5c2e7";
        #     cyan = "#94e2d5"; white = "#a6adc8";
        #   };
        #   bright = {
        #     black = "#585b70"; red = "#f37799"; green = "#89d88b";
        #     yellow = "#ebd391"; blue = "#74a8fc"; magenta = "#f2aede";
        #     cyan = "#6bd7ca"; white = "#bac2de";
        #   };
        #   foreground = "#cdd6f4";
        #   background = "#1e1e2e";
        #   selectionFg = "#cdd6f4";
        #   selectionBg = "#585b70";
        #   cursorText = "#1e1e2e";
        #   cursor = "#f5e0dc";
        # };
      };
      light = {
        mPrimary = "#8839ef";
        mOnPrimary = "#eff1f5";
        mSecondary = "#fe640b";
        mOnSecondary = "#eff1f5";
        mTertiary = "#40a02b";
        mOnTertiary = "#eff1f5";
        mError = "#d20f39";
        mOnError = "#dce0e8";
        mSurface = "#eff1f5";
        mOnSurface = "#4c4f69";
        mSurfaceVariant = "#ccd0da";
        mOnSurfaceVariant = "#6c6f85";
        mOutline = "#a5adcb";
        mShadow = "#dce0e8";
        mHover = "#40a02b";
        mOnHover = "#eff1f5";
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
