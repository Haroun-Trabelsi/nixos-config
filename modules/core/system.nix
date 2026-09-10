{ pkgs, inputs, ... }:
{
  nix = {
    # Pin the flake registry and NIX_PATH to the exact nixpkgs this system was
    # built from. Without this, `nix run nixpkgs#foo`, `nix shell nixpkgs#foo`
    # and `,` (comma, enabled in packages/nix.nix) all resolve "nixpkgs"
    # against the UPSTREAM registry and fetch a different tree than flake.lock
    # — so an ad-hoc tool is a different build from the same-named package in
    # this config, and the answer changes with the calendar.
    registry.nixpkgs.flake = inputs.nixpkgs;
    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];

    # No nix-channels either: channels are the other unpinned path to a
    # different nixpkgs, and nothing here uses them.
    channel.enable = false;

    settings = {
      auto-optimise-store = false;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      substituters = [
        "https://nix-community.cachix.org"
        # Restored with the Hyprland desktop. WITHOUT these, Hyprland and
        # noctalia have no binary cache and nix compiles Hyprland from source —
        # a huge C++ build that saturates every core and freezes the machine.
        "https://hyprland.cachix.org"
        "https://noctalia.cachix.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    wget
    git
  ];

  time.timeZone = "Africa/Tunis";
  i18n.defaultLocale = "en_US.UTF-8";
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "26.05";
}
