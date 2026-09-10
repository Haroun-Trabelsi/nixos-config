# NOTE: uses nixpkgs' hyprland (0.54.3), NOT the upstream flake input.
# The flake input has no binary cache configured for a non-trusted user, so nix
# compiled Hyprland from source and froze the machine. nixpkgs' build is on
# cache.nixos.org and was already in the store. Same 0.54 series, so the config
# syntax below is unaffected.
{
  pkgs,
  osConfig,
  lib,
  ...
}:
{
  # Desktop only. This list was previously OUTSIDE the gate, so the laptop was
  # carrying grimblast (Hyprland-only) plus a second copy of grim, slurp,
  # cliphist, wf-recorder, hyprpicker and tesseract. Those moved to
  # modules/home/wayland-tools.nix; glib and direnv moved to packages/dev.nix,
  # and the bare `wayland` library package was never needed by anything.
  home.packages = lib.mkIf (osConfig.machine.profile == "desktop") (
    with pkgs;
    [
      grimblast # Hyprland's screenshot wrapper
    ]
  );

  systemd.user.targets.hyprland-session.Unit.Wants = lib.mkIf (
    osConfig.machine.profile == "desktop"
  ) [ "xdg-desktop-autostart.target" ];

  wayland.windowManager.hyprland = {
    # desktop only — the laptop runs sway
    enable = osConfig.machine.profile == "desktop";
    xwayland.enable = true;
    systemd.enable = true;
  };
}
