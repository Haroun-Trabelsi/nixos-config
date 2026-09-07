{ pkgs, ... }:
{
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium; # the binary is `codium`, not `code`
  };
}
