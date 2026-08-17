{
  config,
  pkgs,
  lib,
  ...
}:
let
  c = config.theme.colors;
  strip = h: builtins.substring 1 6 h;

  # Was pointed at a colours file that noctalia rewrote at runtime. Now the
  # palette is generated below at build time, so Qt apps are themed without a
  # shell process running.
  qtctConf = variant: ''
    [Appearance]
    color_scheme_path=${config.home.homeDirectory}/.config/${variant}/colors/theme.conf
    custom_palette=true
    icon_theme=Tela-circle-purple-dark
    standard_dialogs=default
    style=breeze

    [Fonts]
    fixed="JetBrains Mono,12,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
    general="JetBrains Mono,12,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
  '';
  # 20 Qt palette roles, repeated for active/disabled/inactive.
  qtRoles = colors: builtins.concatStringsSep ", " colors;
  qtPalette =
    let
      base = [
        c.text c.surface c.overlay c.surface c.mantle c.base c.text
        c.brightWhite c.text c.base c.base c.overlay c.tertiary c.inverse
        c.secondary c.tertiary c.surface c.text c.mantle c.text
      ];
      dim = [
        c.subtext c.surface c.overlay c.surface c.mantle c.base c.subtext
        c.brightWhite c.subtext c.base c.base c.overlay c.overlay c.subtext
        c.secondary c.tertiary c.surface c.subtext c.mantle c.subtext
      ];
    in
    ''
      [ColorScheme]
      active_colors=${qtRoles base}
      disabled_colors=${qtRoles dim}
      inactive_colors=${qtRoles base}
    '';
in
{
  home.packages = with pkgs; [
    kdePackages.dolphin
    (tela-circle-icon-theme.override { colorVariants = [ "purple" ]; })

    # Breeze supplies the Qt widget style + KColorScheme support that Dolphin
    # needs to render a color scheme at all; without it Qt falls back to Fusion,
    # which ignores kdeglobals and leaves black text on a dark background.
    kdePackages.breeze
    kdePackages.qt6ct
    libsForQt5.qt5ct
  ];

  # Replaces the stale caelestia-era confs that pointed at a deleted color file
  # and a style (Darkly) that was never installed.
  xdg.configFile."qt6ct/qt6ct.conf".text = qtctConf "qt6ct";
  xdg.configFile."qt5ct/qt5ct.conf".text = qtctConf "qt5ct";

  # The palette itself, in qt{5,6}ct's colour-scheme format. Order is the Qt
  # ColorGroup roles; the three lists are active/disabled/inactive.
  xdg.configFile."qt6ct/colors/theme.conf".text = qtPalette;
  xdg.configFile."qt5ct/colors/theme.conf".text = qtPalette;

  # Point Dolphin at noctalia's color scheme + Tela icons.
  # kwriteconfig6 merges into kdeglobals (no plasma-workspace needed).
  home.activation.setKdePrefs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 \
      --file kdeglobals --group General --key ColorScheme Eldritch
    run ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 \
      --file kdeglobals --group Icons --key Theme Tela-circle-purple-dark
  '';

  # Every file in the nix store has mtime=1, so KDE's "is my cache stale?" check
  # never fires and newly added .desktop files stay invisible to Dolphin's
  # handler lookup (KApplicationTrader reads sycoca, not the directories).
  # Rebuild it on activation so mime associations track the config.
  home.activation.rebuildKdeSycoca = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run ${pkgs.kdePackages.kservice}/bin/kbuildsycoca6 --noincremental || true
  '';
}
