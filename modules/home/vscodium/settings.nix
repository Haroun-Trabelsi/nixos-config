{ ... }:
{
  programs.vscode = {
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
      "workbench.colorTheme" = "Eldritch";
      "workbench.preferredLightColorTheme" = "Eldritch";
      "workbench.preferredDarkColorTheme" = "Eldritch";
      "window.menuBarVisibility" = "hidden";
      "editor.fontFamily" = "'JetBrains Mono', 'SymbolsNerdFont', monospace";
      "terminal.integrated.fontFamily" = "'Monocraft', 'SymbolsNerdFont'";
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
      "workbench.statusBar.visible" = false;
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
