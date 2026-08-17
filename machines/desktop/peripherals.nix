{ pkgs, config, ... }:
# Hardware that only exists on the tower. All of this used to live in
# modules/core, so the laptop ran an OpenRGB server and an out-of-tree I2C
# module for devices that were not physically present.
{
  environment.systemPackages = with pkgs; [
    deepcool-digital-linux
    openrgb
    ddcutil
  ];

  # DeepCool digital-display service. NOT started at boot; the udev rule below
  # starts it when a DeepCool USB device (vendor 3633) is present or hotplugged,
  # so a missing cooler no longer loops forever or fails nixos-rebuild.
  systemd.services.deepcool-digital = {
    description = "DeepCool Digital cooler display";
    serviceConfig = {
      ExecStart = "${pkgs.deepcool-digital-linux}/bin/deepcool-digital-linux";
      Restart = "on-failure";
      RestartSec = 5;
    };
    startLimitIntervalSec = 60;
    startLimitBurst = 5;
  };

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="3633", TAG+="systemd", ENV{SYSTEMD_WANTS}+="deepcool-digital.service"
  '';

  services.hardware.openrgb = {
    enable = true;
    motherboard = "amd";
  };

  # DDC/CI brightness control for the external monitors. The laptop drives only
  # eDP, where brightness goes through the backlight class instead, so ddcci was
  # polling an I2C bus with nothing on it.
  hardware.i2c.enable = true;
  boot.extraModulePackages = with config.boot.kernelPackages; [ ddcci-driver ];
  users.users.fantasy.extraGroups = [ "i2c" ];
}
