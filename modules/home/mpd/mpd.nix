{ pkgs, ... }:
{
  home.packages = with pkgs; [ mpd ];

  xdg.configFile."mpd/mpd.conf".source = ./mpd.conf;
}
