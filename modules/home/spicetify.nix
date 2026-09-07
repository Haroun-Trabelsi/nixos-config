{ pkgs, inputs, osConfig, ... }:
let
  spicetifyPkgs =
    inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  imports = [ inputs.spicetify-nix.homeManagerModules.spicetify ];

  programs.spicetify = {
    # desktop only; the laptop uses mpd + rmpc for battery reasons
    enable = osConfig.machine.profile == "desktop";
    theme = spicetifyPkgs.themes.text;
    colorScheme = "custom";
    customColorScheme = {
      text = "ebfafa";
      subtext = "ABB4DA";
      sidebar-text = "ebfafa";
      main = "212337";
      sidebar = "171928";
      player = "212337";
      card = "292e42";
      shadow = "171928";
      selected-row = "ABB4DA";
      button = "a48cf2";
      button-active = "37f499";
      button-disabled = "3b4261";
      tab-active-text = "ebfafa";
      notification = "37f499";
      notification-error = "f16c75";
      misc = "292e42";
    };

    enabledExtensions = with spicetifyPkgs.extensions; [
      adblockify
    ];
  };
}
