{ pkgs, ... }:
{
  programs.swaylock = {
    enable = true;

    package = pkgs.swaylock-effects;

    settings = {
      clock = true;
      daemonize = true;
      # timestr="%H:%M";
      datestr = "";
      screenshots = true;
      ignore-empty-password = true;

      indicator = true;
      indicator-radius = 111;
      indicator-thickness = 9;

      effect-blur = "7x5";
      effect-vignette = "0.75:0.75";
      effect-pixelate = 5;

      font = "Maple Mono";
    };
  };
}
