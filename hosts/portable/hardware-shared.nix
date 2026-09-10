{
  config,
  lib,
  modulesPath,
  ...
}:
# The parts of the old generated hardware-configuration.nix that are genuinely
# shared: this is ONE filesystem on ONE portable SSD, plugged into either
# machine, so root/ESP/swap are identical by definition.
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # Root lives on an external USB 3.0 enclosure (UAS bridge 8644:10d1) presented
  # as /dev/sda, which is why `uas`/`usb_storage` matter here and there is no
  # nvme/vmd: the internal Samsung PM9C1a still holds Windows and is untouched.
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "usbhid"
    "usb_storage"
    "uas"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];

  # The one ext4 partition. Where it MOUNTS depends on whether root-on-tmpfs is
  # enabled (modules/core/impermanence.nix): normally it is /, and under
  # impermanence it is /persist with / becoming a tmpfs. The UUID is stated once
  # here either way — this file owns disk facts, that module owns the policy.
  fileSystems.${if config.impermanence.enable then "/persist" else "/"} = {
    device = "/dev/disk/by-uuid/b430a1af-2909-46ad-a25a-968cf448b3f1";
    fsType = "ext4";
    # Under impermanence everything else is bind-mounted out of here, and
    # sops-nix reads the age key from it during activation, so it has to be up
    # before the switch runs.
    neededForBoot = config.impermanence.enable;
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/4486-3BC9";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  # The disk this config currently runs on has a 17 GiB swap partition, from
  # before zram. It is barely used — 209 MiB against 22 GiB of RAM on the tower
  # at the time of writing — and hosts/portable/disko.nix no longer creates one
  # on a fresh install (`enableSwap = false`).
  #
  # `nofail` so a swapless disk boots cleanly regardless: without it systemd
  # blocks on a swap unit whose device does not exist. The ISO installer also
  # empties this list outright when the target disk has no swap partition, so
  # this is belt and braces rather than the primary mechanism.
  swapDevices = [
    {
      device = "/dev/disk/by-uuid/43d2cec0-faf6-4aa8-8977-c0ea90a6a5b9";
      # `nofail` alone is not enough. It stops a missing swap device FAILING the
      # boot, but systemd still creates a device dependency and blocks on it for
      # its default 90 s timeout — observed exactly that in a VM which inherited
      # this UUID: "Timed out waiting for device /dev/disk/by-uuid/43d2cec0...".
      # The short device-timeout is what makes a swapless disk boot promptly
      # rather than merely eventually.
      options = [
        "nofail"
        "x-systemd.device-timeout=5s"
      ];
    }
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.enableRedistributableFirmware = true;

  # BOTH microcodes, deliberately. The disk boots an Intel laptop and an AMD
  # tower, and the kernel's early loader picks by CPU vendor at runtime. Neither
  # nixos module asserts against the other — each only does
  # `boot.initrd.prepend = mkOrder 1 [ ... ]` — so enabling both keeps the initrd
  # byte-identical for base and specialisation, which is what makes the
  # specialisation cost ~191 KB of stub instead of a second 13 MB initrd.
  #
  # Previously only the AMD one was set, so this Intel CPU was running with no
  # microcode update at all.
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
