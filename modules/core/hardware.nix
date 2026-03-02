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

  boot.kernelModules = [
    "iwlwifi"
    "i2c-dev"
  ];

  boot.extraModulePackages = with config.boot.kernelPackages; [
    ddcci-driver
  ];

  environment.systemPackages = with pkgs; [
    ddcutil
  ];
}
