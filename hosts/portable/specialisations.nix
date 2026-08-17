{ ... }:
{
  # Produces a second signed UKI per generation, named
  # nixos-generation-<N>-specialisation-desktop.efi, with its own boot-menu
  # entry. Picking the machine is therefore a boot-time choice with no rebuild
  # before physically moving the disk.
  #
  # inheritParentConfig defaults to true, so this is the whole base config plus
  # machines/desktop. That is also why machines/laptop guards itself with
  # `lib.mkIf (config.machine.profile == "laptop")` — it is still imported here,
  # and would otherwise fight the desktop's settings.
  #
  # Note the bootloader is NOT configured in here: switch-to-configuration
  # installs the bootloader from the PARENT, so lanzaboote has to live in the
  # shared layer (modules/core/bootloader.nix) or a laptop rebuild would install
  # an unsigned bootloader and break Secure Boot on the tower.
  #
  # Useful during development: this switches to the desktop config at runtime
  # without rebooting (everything except the NVIDIA kmod and the cmdline):
  #   sudo /run/current-system/specialisation/desktop/bin/switch-to-configuration test
  specialisation.desktop.configuration = {
    imports = [ ./../../machines/desktop ];
  };
}
