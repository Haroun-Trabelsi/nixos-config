# Disk layout for the portable SSD, for use with the disko CLI:
#
#   disko --mode destroy,format,mount ./hosts/portable/disko.nix
#
# This file is NOT imported by the system configuration. It is a one-shot
# installer input; the running system's mounts live in ./hardware-shared.nix.
# See the note at the bottom on why those are still two places.
#
# It was previously an `import ../../modules/disko-layout.nix { ... }` describing
# THREE partitions in the order ESP -> swap -> root, with root at 100%. That did
# not describe this disk. The real layout is four partitions, and root is not
# 100% — so running the old file would have produced a different disk AND
# destroyed the 146.8 GB exfat data partition without mentioning it.
#
# The indirection through modules/disko-layout.nix is gone with it: there is one
# host, so a parameterised "shared layout" was abstraction over a single caller,
# and it could not express partition labels or a fourth partition anyway.
#
# Captured from the live disk on 2026-09-10 (lsblk -o NAME,PARTLABEL,LABEL,UUID).
{
  disko.devices.disk.main = {
    # Resolves to /dev/sdb today. Deliberately by-id and not by-path or a bare
    # /dev/sd?: this enclosure used to enumerate as sda and now comes up as sdb,
    # because there is a second USB disk in the machine. Anything positional
    # would have silently retargeted to the wrong drive.
    device = "/dev/disk/by-id/ata-USSD_512GB_DTPP2409784000001014";
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        # `priority` fixes the partition NUMBERS. Without it disko walks the
        # attrset, which Nix sorts alphabetically (ESP, data, root, swap), and
        # the numbering would not match the disk it is meant to reproduce.
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
        root = {
          priority = 2;
          label = "root";
          size = "312G";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
        swap = {
          priority = 3;
          # The live partition carries NO partlabel — only the swap area's own
          # label. Declared here so a reinstall gains one; see the note below.
          label = "swap";
          size = "17G";
          content.type = "swap";
        };
        # The ExtNix data partition. Included so this file describes the whole
        # disk rather than three quarters of it.
        #
        # WARNING: `disko --mode destroy,format` FORMATS THIS TOO. 146.8 GB of
        # data lives here and it is not backed up by anything in this repo. On a
        # reinstall where you want to keep it, run disko against a layout without
        # this partition, or back it up first.
        data = {
          priority = 4;
          label = "ExtNix";
          size = "100%";
          content = {
            type = "filesystem";
            format = "exfat";
            mountpoint = null; # mounted on demand by udisks2, not by fstab
          };
        };
      };
    };
  };
}
