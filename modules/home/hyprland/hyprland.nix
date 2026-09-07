# NOTE: uses nixpkgs' hyprland (0.54.3), NOT the upstream flake input.
# The flake input has no binary cache configured for a non-trusted user, so nix
# compiled Hyprland from source and froze the machine. nixpkgs' build is on
# cache.nixos.org and was already in the store. Same 0.54 series, so the config
# syntax below is unaffected.
{ pkgs, osConfig, ... }:
{
  home.packages = with pkgs; [
    grimblast
    hyprpicker
    grim
    slurp
    wl-clip-persist
    cliphist
    wf-recorder
    glib
    wayland
    direnv
    tesseract
  ];

  systemd.user.targets.hyprland-session.Unit.Wants = [ "xdg-desktop-autostart.target" ];

  wayland.windowManager.hyprland = {
    # desktop only — the laptop runs sway
    enable = osConfig.machine.profile == "desktop";
    xwayland.enable = true;
    systemd.enable = true;
  };
}
