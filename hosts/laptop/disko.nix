import ../../modules/disko-layout.nix {
  # Update device with your laptop's disk path
  # Find it with: ls -la /dev/disk/by-id/ | grep -v part
  device = "/dev/sda";
  swapSize = "8G";
}
