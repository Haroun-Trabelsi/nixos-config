{ pkgs, inputs, ... }:
{
  nixpkgs = {
    overlays = [
      (
        final: prev:
        (import ../../pkgs {
          inherit inputs;
          inherit pkgs;
          inherit (prev) system;
        })
      )
      inputs.nur.overlays.default

      # Zed only. See the nixpkgs-zed input in flake.nix for why.
      (final: prev: {
        zed-editor = inputs.nixpkgs-zed.legacyPackages.${prev.stdenv.hostPlatform.system}.zed-editor;
      })
    ];
  };
}
