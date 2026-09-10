{ inputs, ... }:
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
    inputs.disko.nixosModules.disko
    ./../../modules/core
    ./../../machines/laptop
  ];

  # The disk layout is declared INTO the system config so the disko CLI can find
  # it — `disko-install --flake .#portable --disk main /dev/sdX` discovers
  # `disko.devices` from the nixosConfiguration, which is what makes installing
  # onto a new disk a single command with no file editing.
  #
  # enableConfig = false is essential. Left on, disko generates `fileSystems`
  # from the layout, emitting /dev/disk/by-partlabel/... mounts. On the current
  # disk only partitions 1 and 2 carry partlabels (EFI, root) — swap and ExtNix
  # have none — so the generated config would point at devices that do not exist
  # and the machine would not boot. The real mounts stay by-uuid in
  # ./hardware-shared.nix; this option is the switch that keeps them there.
  disko.enableConfig = false;

  # ./disko.nix is CALLED, not imported as a module. It is a function taking an
  # optional `device`, and the module system does not honour default values for
  # function arguments — it insists on resolving `device` from `_module.args`
  # and fails. Calling it explicitly keeps the default inside that file, where
  # it belongs, and leaves `--argstr device` working for the CLI.
  disko.devices = (import ./disko.nix { }).disko.devices;
}
