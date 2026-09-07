{ ... }:
{
  imports = [
    ./sway.nix # compositor, packages, session
    ./variables.nix # session environment
    ./input.nix # keyboard/touchpad/seat
    ./outputs.nix # monitors + workspace pinning
    ./binds.nix # keybindings
    ./rules.nix # window rules
    ./startup.nix # exec-once equivalent
    ./bar.nix # swaybar + i3status-rust
    ./notifications.nix # mako
    ./launcher.nix # fuzzel
  ];
}
