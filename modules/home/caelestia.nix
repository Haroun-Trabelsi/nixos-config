{ inputs, pkgs, ... }:
{
  home.packages = [
    inputs.caelestia-shell.packages.${pkgs.system}.with-cli
  ];

  xdg.configFile."caelestia/shell.json".text = builtins.toJSON {
    appearance = {

      font = {
        family = {
          sans = "Maple Mono 15";
          mono = "Maple Mono 15";
          material = "Material Symbols Rounded";
          clock = "Rubik";
        };
        size.scale = 1;
      };
      anim = {
        mediaGifSpeedAdjustment = 300;
        sessionGifSpeed = 0.7;
        durations.scale = 1;
      };
      transparency = {
        enabled = false;
        base = 0.85;
        layers = 0.4;
      };
    };
    bar = {
      border = {
        rounding = 25;
        thickness = 10;
      };
      workspaces = {
        activeIndicator = true;
        activeLabel = "";
        activeTrail = false;
        label = "";
        occupiedBg = false;
        occupiedLabel = "";
        perMonitorWorkspaces = true;
        showWindows = true;
        shown = 5;
        specialWorkspaceIcons = [
          {
            icon = "sports_esports";
            name = "steam";
          }
        ];
      };
    };
  };
}
