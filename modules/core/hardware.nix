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

  hardware.i2c.enable = true;

  # iwlwifi and i2c-dev are auto-loaded by udev when the hardware is detected,
  # so we don't eagerly load them here. Saves time in systemd-modules-load.
  boot.kernelModules = [ ];

  boot.extraModulePackages = with config.boot.kernelPackages; [
    ddcci-driver
  ];

  environment.systemPackages = with pkgs; [
    ddcutil
  ];
}
