{ ... }:
{
  home.sessionPath = [ ];

  # ONLY shell-scoped variables belong here.
  #
  # home.sessionVariables is written to hm-session-vars.sh, which is sourced by
  # interactive shells and nothing else. greetd execs sway directly, so anything
  # the COMPOSITOR or its children must see is invisible if set here — the same
  # trap modules/core/wayland.nix already documents for QT_QPA_PLATFORMTHEME
  # under LightDM.
  #
  # That trap was live before this migration: NIXOS_OZONE_WL was set here, so
  # Electron apps almost certainly never ran as Wayland clients — which matches
  # the old window rules keying VS Code on `class = "code"`, the XWayland name,
  # rather than an app_id.
  #
  # Everything session-facing now lives in environment.sessionVariables in
  # modules/core/wayland.nix, which lands in /etc/pam/environment and is applied
  # by pam_env to the greetd session.
  home.sessionVariables = {
    DIRENV_LOG_FORMAT = "";
  };
}
