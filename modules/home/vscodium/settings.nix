{ ... }:
{
  programs.vscodium = {
    profiles.default.userSettings = {
      "update.mode" = "none";
      "extensions.autoUpdate" = false; # This stuff fixes vscode freaking out when theres an update

      # --- background CPU ---
      # Telemetry, crash reporting and experiments all poll and phone home on a
      # timer. None of them do anything for you on a battery-powered laptop.
      "telemetry.telemetryLevel" = "off";
      "telemetry.enableTelemetry" = false;
      "telemetry.enableCrashReporter" = false;
      "workbench.enableExperiments" = false;
      "workbench.settings.enableNaturalLanguageSearch" = false;
      "npm.fetchOnlinePackageInfo" = false;
      "extensions.ignoreRecommendations" = true;
      "update.showReleaseNotes" = false;

      # The file watcher walks and inotify-watches every path in the workspace.
      # On a node/python repo that is tens of thousands of files it will never
      # need, and each change wakes the CPU. These are the usual offenders.
      "files.watcherExclude" = {
        "**/.git/objects/**" = true;
        "**/.git/subtree-cache/**" = true;
        "**/node_modules/**" = true;
        "**/.venv/**" = true;
        "**/venv/**" = true;
        "**/__pycache__/**" = true;
        "**/.mypy_cache/**" = true;
        "**/.pytest_cache/**" = true;
        "**/dist/**" = true;
        "**/build/**" = true;
        "**/.next/**" = true;
        "**/target/**" = true;
        "**/result" = true;
        "**/.direnv/**" = true;
      };
      "search.followSymlinks" = false;
      "window.titleBarStyle" = "custom";
      "window.customTitleBarVisibility" = "never";
      # Abyss is BUILT IN to VSCodium (resources/app/extensions/theme-abyss), so
      # unlike a marketplace theme it needs no extension declared to work.
      # These strings are theme labels, not free text: a typo silently falls
      # back to stock Dark+ instead of erroring, which is exactly how the old
      # "Eldritch" value went unnoticed — that extension was never installed
      # here, only in ~/.vscode (real VS Code), never VSCodium's ~/.vscode-oss.
      # preferredLight/Dark only take effect with window.autoDetectColorScheme.
      "workbench.colorTheme" = "Abyss";
      "workbench.preferredDarkColorTheme" = "Abyss";
      # Abyss is dark-only, so the light slot needs a real theme rather than a
      # dangling name. "Light Modern" ships with VSCodium itself.
      "workbench.preferredLightColorTheme" = "Light Modern";
      "window.menuBarVisibility" = "hidden";
      "editor.fontFamily" = "'JetBrains Mono', 'SymbolsNerdFont', monospace";
      "terminal.integrated.fontFamily" = "'Monocraft', 'SymbolsNerdFont'";

      # Make the terminal bell audible (Claude Code and friends ring it when a
      # long job finishes). Every guide on the internet still says to set
      # "terminal.integrated.enableBell", but that key was replaced in 1.86 and
      # is now only a migration shim: VSCodium rewrites it into the signal
      # below and deletes it again, which on a read-only home-manager
      # settings.json means it silently does nothing. Set the real key.
      "accessibility.signals.terminalBell" = {
        sound = "on";
      };
      "editor.fontSize" = 18;
      "workbench.iconTheme" = "catppuccin-macchiato";
      "material-icon-theme.folders.theme" = "classic";
      "vsicons.dontShowNewVersionMessage" = true;
      "explorer.confirmDragAndDrop" = false;
      "editor.fontLigatures" = true;
      "editor.minimap.enabled" = false;
      "workbench.startupEditor" = "none";

      "editor.formatOnSave" = true;
      "editor.formatOnType" = true;
      "editor.formatOnPaste" = true;
      "editor.inlayHints.enabled" = "off";

      "workbench.layoutControl.type" = "menu";
      "window.commandCenter" = false;
      "workbench.navigationControl.enabled" = false;

      # --- Coder remote-SSH ---
      # Adopted from ~/.config/VSCodium/User/settings.json, which VSCodium had
      # been writing itself: until 2026-09-16 this module declared
      # programs.vscode, so home-manager wrote to ~/.config/Code/User and
      # VSCodium read its own untracked file instead. Declaring them here keeps
      # them once home-manager actually owns the path.
      #
      # The long timeouts are the point: a Coder workspace can be asleep when
      # you connect, and the default grace periods drop the session while it is
      # still waking. Hosts match the coder-prefixed/coder-suffixed blocks in
      # modules/home/ssh.nix.
      "remote.SSH.remotePlatform" = {
        "coder-vscodium.dev-env-001.tail74f0ed.ts.net--haroun--haroun.main" = "linux";
      };
      "remote.SSH.connectTimeout" = 1800;
      "remote.SSH.reconnectionGraceTime" = 28800;
      "remote.SSH.serverShutdownTimeout" = 28800;
      "remote.SSH.maxReconnectionAttempts" = null;
      "workbench.editor.limit.enabled" = true;
      "workbench.editor.limit.value" = 10;
      "workbench.editor.limit.perEditorGroup" = true;
      "workbench.editor.showTabs" = "multiple";
      "files.autoSave" = "afterDelay";
      "files.insertFinalNewline" = true;
      "explorer.openEditors.visible" = 0;
      "breadcrumbs.enabled" = false;
      "editor.renderControlCharacters" = false;
      "workbench.activityBar.location" = "hidden";
      "editor.scrollbar.verticalScrollbarSize" = 2;
      "editor.scrollbar.horizontalScrollbarSize" = 2;
      "editor.scrollbar.vertical" = "hidden";
      "editor.scrollbar.horizontal" = "hidden";

      "editor.mouseWheelZoom" = true;

      # C/C++
      "clangd.arguments" = [
        "--clang-tidy"
        "--inlay-hints=false"
      ];

      # Zig
      # "zig.initialSetupDone" = true;
      "zig.checkForUpdate" = false;
      "zig.zls.path" = "zls";
      "zig.path" = "zig";
      "zig.revealOutputChannelOnFormattingError" = false;
      "zig.zls.enableInlayHints" = false;
      "zig.zls.enableArgumentPlaceholders" = false;
      "zig.zls.enableBuildOnSave" = true;
      "zig.zls.buildOnSaveArgs" = [ ];

      "nix.serverPath" = "nixd";
      "nix.enableLanguageServer" = true;
      # "nix.serverSettings" = {
      #   "nixd" = {
      #     "formatting" = {
      #       "command" = [ "nixfmt" ];
      #     };
      #   };
      # };
    };
  };
}
