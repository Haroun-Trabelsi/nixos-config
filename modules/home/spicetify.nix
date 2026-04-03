{ pkgs, inputs, ... }:
let
  spicetifyPkgs =
    inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  imports = [ inputs.spicetify-nix.homeManagerModules.spicetify ];

  programs.spicetify = {
    enable = true;
    theme = spicetifyPkgs.themes.catppuccin;
    colorScheme = "macchiato";

    enabledExtensions = with spicetifyPkgs.extensions; [
      adblock
    ];
  };
}
