{ pkgs, lib, ... }:
{
  # Required for Qt plugins installed into a profile (qt6ct, breeze) to be
  # found at all: it adds /etc/profiles/per-user/$USER/lib/qt-{5,6}/plugins to
  # QT_PLUGIN_PATH. Without it Qt apps only search their own store closure, so
  # QT_QPA_PLATFORMTHEME and the Breeze style silently do nothing.
  qt.enable = true;

  # Must be a *system* sessionVariable, not home.sessionVariables: the greeter
  # execs the compositor directly and never sources hm-session-vars.sh, so
  # anything set there is invisible to sway and everything it launches.
  # environment.sessionVariables lands in /etc/pam/environment, which pam_env
  # does apply to the session.
  environment.sessionVariables = {
    QT_QPA_PLATFORMTHEME = "qt6ct";
    XDG_CURRENT_DESKTOP = "sway";
    XDG_SESSION_DESKTOP = "sway";
    XDG_SESSION_TYPE = "wayland";
  };

  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
  };

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = false;
    config = {
      common.default = [ "gtk" ];
      sway = {
        # xdg-desktop-portal-wlr provides ScreenCast on wlroots compositors.
        # This is what Discord/OBS screen sharing goes through — without it
        # screen share silently produces a black frame.
        #
        # mkForce because nixpkgs' own programs/wayland/sway.nix already defines
        # this as just "gtk", and two definitions of a non-list option conflict.
        default = lib.mkForce [
          "wlr"
          "gtk"
        ];
        "org.freedesktop.impl.portal.OpenURI" = [ "gnome" ];
      };
    };

    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-wlr
      pkgs.xdg-desktop-portal-gnome
    ];
  };
}
