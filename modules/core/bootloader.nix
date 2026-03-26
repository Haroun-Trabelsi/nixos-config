{ pkgs, ... }:
{
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      systemd-boot.configurationLimit = 10;
    };

    kernelPackages = pkgs.linuxPackages_latest;
    # load nintendo controller support on demand, not at boot
    extraModulePackages = [ ];
    kernelModules = [ ];
    supportedFilesystems = [ "ntfs" ];
  };
}
