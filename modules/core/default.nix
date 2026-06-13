{ ... }:
{
  imports = [
    ./nixpkgs.nix
    ./bootloader.nix
    ./hardware.nix
    ./xserver.nix
    ./network.nix
    ./bluetooth.nix
    ./nh.nix
    ./pipewire.nix
    ./program.nix
    ./security.nix
    ./services.nix
    ./system.nix
    ./flatpak.nix
    ./miracast.nix
    ./deepcool.nix
    ./user.nix
    ./wayland.nix
    ./qmk.nix
    ./sops.nix
    ./steam.nix
    ./sunshine.nix
  ];
}
