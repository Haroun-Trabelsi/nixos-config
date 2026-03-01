{ inputs, pkgs, ... }:
{
  home.packages = [
    inputs.caelestia-shell.packages.${pkgs.system}.with-cli
  ];
}
