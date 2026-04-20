{ pkgs, ... }:
{
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      systemd-boot.configurationLimit = 10;
      timeout = 0;
    };

    plymouth = {
      enable = true;
      theme = "tech_a";
      themePackages = [
        (pkgs.adi1090x-plymouth-themes.override { selected_themes = [ "tech_a" ]; })
      ];
    };

    # silence boot so plymouth is actually visible
    kernelParams = [ "quiet" "splash" "loglevel=3" "rd.systemd.show_status=false" "rd.udev.log_level=3" "udev.log_priority=3" ];
    consoleLogLevel = 0;
    initrd.verbose = false;

    kernelPackages = pkgs.linuxPackages_latest;
    # load nintendo controller support on demand, not at boot
    extraModulePackages = [ ];
    kernelModules = [ ];
    supportedFilesystems = [ "ntfs" ];
  };
}
