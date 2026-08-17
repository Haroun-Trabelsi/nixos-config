{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./../../modules/core
    ./ollama.nix
    ./tv-audio.nix
    inputs.lanzaboote.nixosModules.lanzaboote
  ];

  # Secure Boot via Lanzaboote — replaces systemd-boot
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";

    # Always show the generation list, with no countdown and no key held down.
    # loader.conf(5): "menu-force" disables the timeout while always showing the
    # menu. It has to be set here rather than via boot.loader.timeout because
    # that option is typed `null or signed integer`; lanzaboote.settings is a
    # freeform attrset written straight into loader.conf, so it accepts it.
    settings.timeout = "menu-force";
  };

  # NVIDIA
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    open = true; # RTX 5060 Ti (Blackwell) — open module is mandatory; proprietary doesn't support 50-series
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  environment.systemPackages = with pkgs; [
    acpi
    brightnessctl
    cpupower-gui
    powertop
    nvtopPackages.nvidia
    sbctl # Secure Boot key management for Lanzaboote
  ];

  services = {
    power-profiles-daemon.enable = false;

    upower = {
      enable = true;
      percentageLow = 20;
      percentageCritical = 5;
      percentageAction = 3;
      criticalPowerAction = "PowerOff";
    };

    tlp.enable = true;
    tlp.settings = {
      START_CHARGE_THRESH_BAT0 = 60;
      STOP_CHARGE_THRESH_BAT0 = 80;
      CPU_ENERGY_PERF_POLICY_ON_AC = "power";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 1;

      CPU_HWP_DYN_BOOST_ON_AC = 1;
      CPU_HWP_DYN_BOOST_ON_BAT = 1;

      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "performance";

      INTEL_GPU_MIN_FREQ_ON_AC = 500;
      INTEL_GPU_MIN_FREQ_ON_BAT = 500;
      # INTEL_GPU_MAX_FREQ_ON_AC=0;
      # INTEL_GPU_MAX_FREQ_ON_BAT=0;
      # INTEL_GPU_BOOST_FREQ_ON_AC=0;
      # INTEL_GPU_BOOST_FREQ_ON_BAT=0;

      # PCIE_ASPM_ON_AC = "default";
      # PCIE_ASPM_ON_BAT = "powersupersave";
    };
  };

  powerManagement.cpuFreqGovernor = "performance";

  boot = {
    kernelModules = [ "acpi_call" ];
    extraModulePackages =
      with config.boot.kernelPackages;
      [
        acpi_call
        cpupower
      ]
      ++ [ pkgs.cpupower-gui ];

    # Bad-RAM reservations from MemTest86 (2026-05-13, 3 passes).
    # Coalesced bad-page clusters at ~15.1 GiB — single DIMM likely failing, RMA pending.
    # Total reserved: ~735 KiB across 8 ranges.
    kernelParams = [
      "memmap=0x40000\$0x3c5e00000" # 256 KiB
      "memmap=0x5000\$0x3c623b000"  # 20 KiB
      "memmap=0xd000\$0x3c6640000"  # 52 KiB
      "memmap=0x3000\$0x3c675c000"  # 12 KiB
      "memmap=0x2b000\$0x3c974b000" # 172 KiB
      "memmap=0x1000\$0x3cda04000"  # 4 KiB
      "memmap=0x31000\$0x3cdb40000" # 196 KiB
      "memmap=0x5000\$0x3ce65b000"  # 20 KiB
    ];
  };
}
