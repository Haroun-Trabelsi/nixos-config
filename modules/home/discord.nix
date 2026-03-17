{ pkgs, ... }:
{
  home.packages = with pkgs; [
    vesktop
    steam
  ];
}
