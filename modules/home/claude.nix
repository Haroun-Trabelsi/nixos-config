{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # webcord
    claude-code
  ];
}
