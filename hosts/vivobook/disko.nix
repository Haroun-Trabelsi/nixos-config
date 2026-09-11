# Disk layout for the Vivobook's INTERNAL NVMe — the disk that held Windows.
#
#   disko --mode destroy,format,mount --argstr device /dev/nvme0n1 \
#     ./hosts/vivobook/disko.nix
#
# There is no default device on purpose. The portable layout can default safely
# because that disk is identified by a unique by-id string; an internal NVMe is
# /dev/nvme0n1 on almost every laptop, including the tower, so a default here
# would be an invitation to format the wrong machine. The installer requires the
# device explicitly and checks the machine's DMI before touching it.
{ device, ... }:
{
  disko.devices.disk.main = {
    inherit device;
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          priority = 1;
          label = "EFI";
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
          label = "nixos";
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
}
