{ inputs, ... }:
{
  nixpkgs = {
    overlays = [
      # `final`, NOT a `pkgs` threaded in from flake.nix. It used to be the
      # latter, which meant flake.nix did a SECOND `import nixpkgs {}` with no
      # overlays and built every package in ../../pkgs from it. Consequences:
      # those packages could not see NUR or the zed pin, they ignored any
      # nixpkgs.config set by a module (only flake.nix's own allowUnfree
      # applied), and the whole of nixpkgs was evaluated twice per build.
      #
      # `final` is the fully-overlaid package set, so callPackage inside
      # ../../pkgs now composes with every other overlay here.
      (
        final: _prev:
        import ../../pkgs {
          inherit inputs;
          pkgs = final;
        }
      )
      inputs.nur.overlays.default

      # Zed only. See the nixpkgs-zed input in flake.nix for why.
      (final: prev: {
        zed-editor =
          inputs.nixpkgs-zed.legacyPackages.${prev.stdenv.hostPlatform.system}.zed-editor;
      })
    ];
  };
}
