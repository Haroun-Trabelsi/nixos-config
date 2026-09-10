{ ... }:
{
  imports = [
    ./machine.nix
    ./nixpkgs.nix
    ./bootloader.nix
    ./hardware.nix
    ./session.nix
    ./network.nix
    ./tailscale.nix
    ./bluetooth.nix
    ./browser-policies.nix
    ./nh.nix
    ./pipewire.nix
    ./program.nix
    ./security.nix
    ./services.nix
    ./system.nix
    ./user.nix
    ./wayland.nix
    ./qmk.nix
    ./sops.nix
  ];
}
