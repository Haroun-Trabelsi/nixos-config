{ config, ... }:
{
  home.sessionPath = [ ];
  home.sessionVariables = {
    XDG_DATA_DIRS = "$XDG_DATA_DIRS:/var/lib/flatpak/exports/share:${config.home.homeDirectory}/.local/share/flatpak/exports/share";
    NIXOS_OZONE_WL = 1;
    SSH_AUTH_SOCK = "/run/user/1000/ssh-agent";
    DISABLE_QT5_COMPAT = 0;
    GDK_BACKEND = "wayland";
    ANKI_WAYLAND = 1;
    DIRENV_LOG_FORMAT = "";
    QT_AUTO_SCREEN_SCALE_FACTOR = 1;
    QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;
    QT_QPA_PLATFORM = "wayland";
    # QT_QPA_PLATFORMTHEME deliberately lives in modules/core/wayland.nix:
    # home.sessionVariables never reach the LightDM-launched session, so setting
    # it here only ever affected interactive shells. See that file for details.
    MOZ_ENABLE_WAYLAND = 1;
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "Hyprland";
    SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland";
    GRIMBLAST_HIDE_CURSOR = 0;

    # Removed from here, deliberately:
    #
    #   GBM_BACKEND=nvidia-drm, __GLX_VENDOR_LIBRARY_NAME=nvidia,
    #   LIBVA_DRIVER_NAME, __GL_GSYNC_ALLOWED, __GL_VRR_ALLOWED
    #     NVIDIA-specific, and this file applies to BOTH machines — the laptop's
    #     Iris Xe was being pointed at a GBM backend and a VA-API driver that do
    #     not exist on it. They are now set per machine at the NixOS level
    #     (machines/{laptop/graphics,desktop/nvidia}.nix), which is also the only
    #     layer that actually reaches a display-manager-launched session:
    #     home.sessionVariables is sourced from hm-session-vars.sh, which the DM
    #     never reads. Same reasoning as the QT_QPA_PLATFORMTHEME note above.
    #
    #   WLR_BACKEND=vulkan, WLR_RENDERER=vulkan, WLR_NO_HARDWARE_CURSORS,
    #   WLR_DRM_NO_ATOMIC
    #     wlroots workarounds for the NVIDIA desktop. On Iris Xe the GLES2
    #     renderer is the cheaper default, and a SOFTWARE cursor is strictly
    #     worse for power: it damages and recomposites the region on every mouse
    #     move, where a hardware cursor plane costs nothing.
  };
}
