{
  pkgs,
  config,
  ...
}:
{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.enableRedistributableFirmware = true;

  # VA-API for the Intel iGPU. There was previously no VA-API driver installed
  # at all — /run/opengl-driver/lib/dri had iris_dri.so and nvidia_drv_video.so
  # but no iHD_drv_video.so — so all browser video decode ran in software. On
  # Raptor Lake-P that is 6-12 W for 1080p60; the fixed-function VDBOX does the
  # same work at 1-2 W. LIBVA_DRIVER_NAME is still "nvidia" and gets switched to
  # "iHD" in the power-tuning phase; this only makes the driver exist.
  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver
    vpl-gpu-rt
  ];

  # iwlwifi and i2c-dev are auto-loaded by udev when the hardware is detected,
  # so we don't eagerly load them here. Saves time in systemd-modules-load.
  boot.kernelModules = [ ];

  # hardware.i2c + the out-of-tree ddcci-driver + ddcutil were here for DDC/CI
  # brightness control of an external desktop monitor. This laptop drives only
  # eDP, where brightness goes through the backlight class instead, so the
  # module was polling I2C for a bus with nothing on it. They move to the
  # desktop-only module in the specialisation phase.
  boot.extraModulePackages = [ ];

  environment.systemPackages = with pkgs; [
    libva-utils # vainfo — verify hardware decode is actually being used
    intel-gpu-tools # intel_gpu_top — RC6 residency and video engine busy%
  ];
}
