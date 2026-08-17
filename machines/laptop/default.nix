{
  pkgs,
  lib,
  config,
  ...
}:
# ASUS Vivobook X1502VA — Intel i5-13500H (4P+8E), Iris Xe iGPU only,
# Intel Wi-Fi 6 AX200, 36.6 Wh battery, eDP-1 + HDMI-A-1.
#
# Everything is guarded by machine.profile because a specialisation INHERITS the
# parent's modules: the `desktop` specialisation still imports this tree, and
# without the guard its TLP block and the desktop's would both apply and fight.
{
  imports = [
    ./power.nix
    ./graphics.nix
  ];

  config = lib.mkIf (config.machine.profile == "laptop") {
    environment.systemPackages = with pkgs; [
      acpi
      brightnessctl
      powertop # measurement only — powerManagement.powertop.enable stays OFF, see below
    ];

    services = {
      # TLP is the single owner of the power sysfs knobs. Both must not run or
      # they fight non-deterministically over the same files.
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
        # The bulk of the tuning lives in ./power.nix; these two are the
        # battery-care settings that are independent of it.
        settings = {
          # ASUS firmware exposes only charge_control_end_threshold. There is no
          # start threshold on this platform, so START_CHARGE_THRESH_BAT0 (which
          # the old desktop-derived config set to 60) is silently rejected.
          STOP_CHARGE_THRESH_BAT0 = 80;
          RESTORE_THRESHOLDS_ON_BAT = 1;
        };
      };
    };

    # Deliberately NOT setting powerManagement.cpuFreqGovernor. The old config
    # pinned it to "performance", which under intel_pstate + HWP also pins the
    # energy-performance preference and silently voids every TLP EPP setting.
    # Unset lets intel_pstate use its powersave (HWP-driven) governor, which
    # ./power.nix then steers via CPU_ENERGY_PERF_POLICY_*.
    #
    # Also NOT enabling powerManagement.powertop: it runs `powertop --auto-tune`
    # once at boot, fights TLP over the same sysfs, and sets power/control=auto
    # on every USB device — including the UAS bridge holding this root filesystem.
  };
}
