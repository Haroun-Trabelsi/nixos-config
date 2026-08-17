{ ... }:
# One portable SSD, two machines.
#
# The BASE of this config is the laptop — the minimal machine. The tower is a
# `specialisation` layered on top, because the module system adds cleanly but
# cannot remove: a specialisation can append kernel params, but it cannot un-set
# services.xserver.videoDrivers or delete a fileSystems entry. Building it the
# other way round would mean the laptop inherited the NVIDIA stack.
{
  imports = [
    ./hardware-shared.nix
    ./specialisations.nix
    ./../../modules/core
    ./../../machines/laptop
  ];
}
