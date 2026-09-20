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

    # PINNED, and not cosmetically. configType's default is gated on
    # home.stateVersion ("legacy" = hyprlang, "current" = lua), so the
    # 2026-09-15 home-manager bump silently switched this config's whole output
    # format from ~/.config/hypr/hyprland.conf to hyprland.lua — with no option
    # of ours changing. Hyprland then refused to load the result and came up on
    # its default config with the error overlay. Three separate breakages, all
    # from that one flip:
    #
    #   "$mod" = "SUPER"   -> hl.$mod("SUPER")     `$` is not a Lua identifier
    #   settings.exec-once -> hl.exec-once(...)    parses as `hl.exec` - `once`
    #   monitors.nix's     -> raw hyprlang `source = ...` lines emitted into a
    #   extraConfig           .lua file
    #
    # and past those, the generator calls hl.animations(), which the Hyprland in
    # nixpkgs 26.11 (0.56.2) does not have — so the lua path is not merely a
    # porting job, it needs a newer Hyprland than this channel ships.
    #
    # Moving to lua is therefore a deliberate project for when the versions line
    # up, not something to absorb during an unrelated release upgrade.
    configType = "hyprlang";
  };
}
