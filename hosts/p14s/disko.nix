import ../../modules/disko-layout.nix {
  # Update device with your P14s disk path
  # Find it with: ls -la /dev/disk/by-id/ | grep -v part
  device = "/dev/nvme0n1";
  swapSize = "8G";
}
