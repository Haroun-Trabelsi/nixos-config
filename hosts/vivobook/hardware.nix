{
  config,
  lib,
  modulesPath,
  ...
}:
# Hardware for the Vivobook's internal install.
#
# Differs from hosts/portable/hardware-shared.nix in two ways that matter:
#
#   * root is an internal NVMe, not a USB 3.0 UAS enclosure. `nvme` is what
#     stage 1 needs; `uas`/`usb_storage` are not required to find root (they are
#     in NixOS's default set anyway, so plugging the portable disk in still
#     works).
#   * only the INTEL microcode. The portable disk needs both because it boots an
#     AMD tower as well; this machine is Intel and only Intel.
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usbhid"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];

  # ── UUIDs ──────────────────────────────────────────────────────────────────
  # These are PLACEHOLDERS. scripts/recovery/install-to-disk.sh rewrites them
  # with the real values after disko has formatted the target, before the config
  # is installed — see the two-phase note in that script.
  #
  # They are deliberately all-zero rather than plausible: a config that somehow
  # reached a real machine with these still in place fails to find root and says
  # so, instead of quietly mounting whatever disk happened to match.
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/00000000-0000-0000-0000-000000000000";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/0000-0000";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  # No swap partition: hosts/vivobook/disko.nix does not create one, and
  # machines/laptop/power.nix runs zramSwap at 50% of RAM, which covers paging
  # without touching the disk. Hibernation is not used here.
  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
