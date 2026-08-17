{ lib, ... }:
{
  # Which physical machine this generation is booting.
  #
  # One portable SSD is moved between two computers, and both boot from the same
  # ESP, so the difference cannot live in separate nixosConfigurations: there is
  # one bootloader install, and under Lanzaboote a rebuild that omitted it would
  # drop an unsigned systemd-boot over the signed one and break Secure Boot on
  # the desktop. Instead the desktop is a NixOS `specialisation` — its own signed
  # boot entry, chosen from the menu with no rebuild before moving the disk.
  #
  # This replaces the old `host` specialArg, which could not work here:
  # specialArgs are fixed per nixosConfiguration and cannot vary per
  # specialisation. This is a normal option, so the specialisation can set it,
  # and home-manager modules can read it as `osConfig.machine.profile`.
  #
  # The default MUST be the laptop. The module system adds cleanly but cannot
  # remove: a specialisation can append kernel params, but it cannot un-set
  # `services.xserver.videoDrivers` or delete a `fileSystems` entry. So the base
  # is the minimal machine and the desktop is a purely additive overlay.
  options.machine.profile = lib.mkOption {
    type = lib.types.enum [
      "laptop"
      "desktop"
    ];
    default = "laptop";
    description = ''
      "laptop" = ASUS Vivobook X1502VA (Intel i5-13500H, Iris Xe, battery).
      "desktop" = AMD tower with an RTX 5060 Ti, set by the `desktop`
      specialisation. Machine-specific modules gate on this with
      `lib.mkIf (config.machine.profile == "...")`.
    '';
  };
}
