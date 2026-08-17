{
  pkgs,
  lib,
  config,
  ...
}:
# ASUS Vivobook X1502VA — Intel i5-13500H (4P+8E), Iris Xe iGPU only,
# Intel Wi-Fi 6 AX200, 36.6 Wh battery, eDP-1 + HDMI-A-1.
#
# Everything is wrapped in mkIf because a specialisation INHERITS the parent's
# modules: the `desktop` specialisation still imports this file, and without the
# guard its TLP block and the desktop's would both apply and fight.
lib.mkIf (config.machine.profile == "laptop") {
  environment.systemPackages = with pkgs; [
    acpi
    brightnessctl
    powertop # measurement only — powerManagement.powertop.enable stays OFF, see below
  ];

  services = {
    # TLP is the single owner of the power sysfs knobs. Both must be off or they
    # fight non-deterministically over the same files.
    power-profiles-daemon.enable = false;

    upower = {
      enable = true;
      percentageLow = 20;
      percentageCritical = 10;
      percentageAction = 5;
      criticalPowerAction = "HybridSleep";
    };

    tlp = {
      enable = true;
      settings = {
        # ASUS firmware exposes only charge_control_end_threshold. There is no
        # start threshold on this platform, so START_CHARGE_THRESH_BAT0 (which
        # the old desktop-derived config set to 60) is silently rejected.
        STOP_CHARGE_THRESH_BAT0 = 80;
        RESTORE_THRESHOLDS_ON_BAT = 1;
      };
    };
  };

  # Deliberately NOT setting powerManagement.cpuFreqGovernor here. The desktop
  # config pinned it to "performance", which under intel_pstate + HWP also pins
  # the energy-performance preference to "performance" and makes every TLP EPP
  # setting a no-op — TLP asked for "power" while sysfs read "performance".
  # Leaving it unset lets intel_pstate use its powersave (HWP-driven) governor.
  # Real EPP/boost tuning lands in the power-tuning phase.
  #
  # Also NOT enabling powerManagement.powertop: it runs `powertop --auto-tune`
  # once at boot, fights TLP over the same sysfs, and sets power/control=auto on
  # every USB device — including the UAS bridge this root filesystem lives on.
}
