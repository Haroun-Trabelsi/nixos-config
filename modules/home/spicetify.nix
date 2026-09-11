{
  pkgs,
  inputs,
  osConfig,
  ...
}:
let
  spicetifyPkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};

  # Caelestia's Spotify theme. spicetify-nix does not package it (27 themes,
  # none named caelestia), and upstream ships it as a single user.css with NO
  # color.ini: it restyles shape and motion only — rounded controls, hover
  # transitions, hidden home header, gradient filter chips — and takes every
  # colour from the `--spice-*` CSS variables.
  #
  # That is precisely why it drops in without a fight. `colorScheme = "custom"`
  # below still supplies the frozen Eldritch palette from theme.nix, so this
  # buys caelestia's polish WITHOUT importing caelestia's colours, and the
  # single-source-of-truth palette stays intact.
  #
  # Pinned to the commit that last touched the file (2026-05-15) rather than
  # `main`, so an unrelated rebuild can never silently restyle Spotify.
  caelestiaUserCss = pkgs.fetchurl {
    url =
      "https://raw.githubusercontent.com/caelestia-dots/caelestia/"
      + "2d55cc3a845788682404f81c5cc1faeec97a553b"
      + "/spicetify/Themes/caelestia/user.css";
    sha256 = "16n4vmjiz2spqg6l9znc0f8wkbpfp9bmjry8j2zfazyhlglk7wm9";
  };

  # spicetify-nix wants { name; src; } where src is a DIRECTORY laid out like a
  # spicetify theme, not the stylesheet itself.
  caelestiaTheme = {
    name = "caelestia";
    src = pkgs.runCommand "caelestia-spicetify-theme" { } ''
      mkdir -p "$out"
      cp ${caelestiaUserCss} "$out/user.css"
    '';
  };
in
{
  imports = [ inputs.spicetify-nix.homeManagerModules.spicetify ];

  programs.spicetify = {
    # desktop only; the laptop uses mpd + rmpc for battery reasons
    enable = osConfig.machine.profile == "desktop";
    theme = caelestiaTheme;
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
