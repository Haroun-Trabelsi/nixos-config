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

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/b430a1af-2909-46ad-a25a-968cf448b3f1";
    fsType = "ext4";
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
      options = [ "nofail" ];
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
