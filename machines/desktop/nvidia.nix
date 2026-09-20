{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;

    # Installs nvidia-suspend/nvidia-resume, which save and restore VRAM around
    # S3. Without them this GPU came back from suspend unable to modeset at all
    # ("Failed to initialize semaphore for plane fence", then "Failed to apply
    # atomic modeset. Error code: -11", Xid 13, Hyprland SIGABRT) — a black
    # screen recoverable only by holding the power button.
    #
    # The 30-minute auto-suspend that kept triggering that is gone from the idle
    # ladder (modules/home/lock.nix); this is for the manual Suspend entry in the
    # power menu. UNVERIFIED on Blackwell + the open module: test it once by
    # hand. If resume still dies, drop this back to false and take Suspend out of
    # scripts/scripts/power-menu.sh instead.
    powerManagement.enable = true;
    open = true; # RTX 5060 Ti (Blackwell) — open module is mandatory; proprietary doesn't support 50-series
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # These were previously in modules/home/hyprland/variables.nix, which meant the
  # laptop's Iris Xe was being told to use an NVIDIA GBM backend and an NVIDIA
  # VA-API driver that were not present.
  #
  # They belong at the NixOS level rather than in home.sessionVariables: the
  # display manager execs the compositor directly and never sources
  # hm-session-vars.sh, so anything set there is invisible to the session.
  # environment.sessionVariables lands in /etc/pam/environment, which pam_env
  # does apply. (Same reasoning as the QT_QPA_PLATFORMTHEME note in wayland.nix.)
  environment.sessionVariables = {
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME = "nvidia";
    __GL_GSYNC_ALLOWED = "0";
    __GL_VRR_ALLOWED = "0";
  };
}
