{ lib, config, ... }:
lib.mkIf (config.machine.profile == "laptop") {
  services.tlp.settings = {
    # --- CPU ---------------------------------------------------------------
    # Under intel_pstate in active mode, "powersave" is the HWP-DRIVEN governor,
    # not a slow one: it hands arbitration to the energy-performance preference
    # below. The old config pinned cpuFreqGovernor to "performance", which also
    # pins EPP to performance and makes every setting here a no-op — TLP asked
    # for "power" while sysfs read "performance". That pin is gone with the
    # laptop base, so these finally take effect.
    CPU_SCALING_GOVERNOR_ON_AC = "powersave";
    CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
    CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
    CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";

    # Boost stays on mains (nix builds want it) and off on battery, where the
    # last few hundred MHz cost disproportionate power.
    CPU_BOOST_ON_AC = 1;
    CPU_BOOST_ON_BAT = 0;
    CPU_HWP_DYN_BOOST_ON_AC = 1;
    CPU_HWP_DYN_BOOST_ON_BAT = 0;

    # --- Platform ----------------------------------------------------------
    # /sys/firmware/acpi/platform_profile was pinned to "performance", holding
    # RAPL PL1 = PL2 = 82 W on a 36.6 Wh battery. Choices are quiet/balanced/
    # performance. Verify: cat /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw
    PLATFORM_PROFILE_ON_AC = "balanced";
    PLATFORM_PROFILE_ON_BAT = "quiet";

    # --- Runtime PM / PCIe -------------------------------------------------
    # Every PCI device was reading power/control=on, so nothing entered D3.
    # If Wi-Fi becomes flaky, AX200 + ASPM L1.2 is the usual suspect: add
    # RUNTIME_PM_DENYLIST = "02:00.0".
    RUNTIME_PM_ON_AC = "auto";
    RUNTIME_PM_ON_BAT = "auto";
    PCIE_ASPM_ON_AC = "default";
    PCIE_ASPM_ON_BAT = "powersupersave";

    # --- USB ---------------------------------------------------------------
    # CRITICAL: 8644:10d1 is the UAS bridge this root filesystem lives on.
    # UAS enclosures are notorious for throwing I/O errors when they come back
    # from autosuspend, and suspending the root disk mid-write is unrecoverable.
    # The denylist is mandatory, not optional.
    #
    # (This is also why SATA_LINKPWR_* is absent: there are zero ATA ports on
    # this machine — /sys/class/ata_port is empty — so those knobs are no-ops.)
    USB_AUTOSUSPEND = 1;
    USB_DENYLIST = "8644:10d1";

    # --- Radios / audio ----------------------------------------------------
    # Wi-Fi power save costs 5-50 ms of extra latency, which is felt on
    # interactive SSH. Kept off on mains for that reason.
    WIFI_PWR_ON_AC = "off";
    WIFI_PWR_ON_BAT = "on";

    # snd_hda_intel power_save was already 1; the *controller* knob was missing.
    SOUND_POWER_SAVE_ON_AC = 1;
    SOUND_POWER_SAVE_ON_BAT = 1;
    SOUND_POWER_SAVE_CONTROLLER = "Y";
  };

  # Routine paging never touches the USB link. The 17 GB partition on /dev/sda3
  # stays as the low-priority backstop (zram takes priority 100 by default here).
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  boot.kernelParams = [
    # /sys/power/mem_sleep reads "[s2idle] deep" — S3 is available and was
    # unused. s2idle on ASUS frequently fails to reach S0i3, costing ~1.5 W
    # while suspended against ~0.3 W for S3. On 36.6 Wh that is losing ~30% of
    # the battery overnight instead of ~6%.
    # TEST RESUME 5x, INCLUDING LID CLOSE, before trusting this.
    "mem_sleep_default=deep"

    # GuC submission + HuC firmware loading. Also a prerequisite for the
    # lowest-power media pipeline used by VA-API decode.
    "i915.enable_guc=3"
    # Framebuffer compression: fewer memory reads to scan out an unchanged screen.
    "i915.enable_fbc=1"

    # NOT setting i915.enable_psr / enable_psr2_sel_fetch here. Panel self-refresh
    # is the biggest display-pipe saving left, but on ASUS panels it can flicker
    # or flash black, and the failure mode is intermittent enough that bundling
    # it with anything else makes the regression ambiguous. It goes in alone.
  ];

  # Radio power save, matching the TLP setting above.
  networking.networkmanager.wifi.powersave = true;
}
