# Disk layout for the portable SSD, for use with the disko CLI:
#
#   disko --mode destroy,format,mount ./hosts/portable/disko.nix
#
# This file is NOT imported by the system configuration. It is a one-shot
# installer input; the running system's mounts live in ./hardware-shared.nix.
#
# It previously described THREE partitions in the order ESP -> swap -> root with
# root at 100%, which did not describe this disk and would have destroyed the
# exfat data partition without mentioning it. It now defaults to the MINIMUM
# useful layout and everything beyond that is opt-in, because a destructive
# installer should never create a partition you did not ask for.
# Takes an optional `device` so the same layout can target another disk without
# editing this file:
#
#   disko --mode destroy,format,mount --argstr device /dev/sdX \
#     ./hosts/portable/disko.nix
#
# The `...` is required: this file is also in the nixosConfiguration's imports
# (see ./default.nix), where the module system calls it with its own arguments.
{
  device ? "/dev/disk/by-id/ata-USSD_512GB_DTPP2409784000001014",
  ...
}:
let
  # ── Fresh-install switches ───────────────────────────────────────────────
  #
  # Both default to false. A new install therefore gets exactly two partitions:
  # a 1 GiB ESP and root across the rest of the disk.

  # A dedicated swap partition.
  #
  # Off by default: not necessary here. The laptop runs zramSwap at 50% of RAM
  # (machines/laptop/power.nix), which handles routine paging in compressed RAM
  # and never touches the USB link — and hibernation is already ruled out on
  # this hardware, so the one thing a real swap partition would buy is unused
  # (see the criticalPowerAction note in machines/laptop/default.nix).
  #
  # The disk this config currently runs on DOES have a 17 GiB swap partition,
  # from before that reasoning. Nothing needs it: at the time of writing the
  # tower was using 209 MiB of it against 22 GiB of RAM.
  #
  # Turn it on if you add hibernation (which also needs `resume=` on the
  # cmdline and swap >= RAM), or if you want a disk backstop on the tower,
  # which has no zram.
  enableSwap = false;

  # A general-purpose exfat data partition ("ExtNix" on the current disk,
  # 146.8 GiB, mounted on demand by udisks2 rather than from fstab).
  #
  # Off by default: it is storage, not part of the system, and a fresh install
  # should not silently carve a third of the disk away from root. Turn it on
  # when you actually want it — and note that `disko --mode destroy,format`
  # FORMATS it, so it is not a place to keep the only copy of anything.
  enableDataPartition = false;

  # The default above resolves to /dev/sdb today. Deliberately by-id rather than
  # by-path or a bare /dev/sd?: this enclosure used to enumerate as sda and now
  # comes up as sdb, because there is a second USB disk in the machine. Anything
  # positional would have silently retargeted to the wrong drive.

  # `priority` fixes the partition NUMBERS. Without it disko walks the attrset,
  # which Nix sorts alphabetically (ESP, data, root, swap), and the numbering
  # would not match a disk built from an earlier run of this file.
  espPartition = {
    ESP = {
      priority = 1;
      label = "EFI"; # matches the existing partlabel, not disko's default
      size = "1G";
      type = "EF00";
      content = {
        type = "filesystem";
        format = "vfat";
        mountpoint = "/boot";
        mountOptions = [
          "fmask=0077"
          "dmask=0077"
        ];
      };
    };
  };

  rootPartition = {
    root = {
      priority = 2;
      label = "root";
      # Root takes the whole disk unless the data partition is claiming a slice.
      size = if enableDataPartition then "312G" else "100%";
      content = {
        type = "filesystem";
        format = "ext4";
        mountpoint = "/";
      };
    };
  };

  swapPartition = {
    swap = {
      priority = 3;
      label = "swap";
      size = "17G";
      content.type = "swap";
    };
  };

  dataPartition = {
    data = {
      priority = 4;
      label = "ExtNix";
      size = "100%";
      content = {
        type = "filesystem";
        format = "exfat";
        mountpoint = null; # mounted on demand by udisks2, not from fstab
      };
    };
  };
in
{
  disko.devices.disk.main = {
    inherit device;
    type = "disk";
    content = {
      type = "gpt";
      partitions =
        espPartition
        // rootPartition
        // (if enableSwap then swapPartition else { })
        // (if enableDataPartition then dataPartition else { });
    };
  };
}
