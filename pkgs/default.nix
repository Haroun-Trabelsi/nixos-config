# `pkgs` here is the overlay's `final` (see modules/core/nixpkgs.nix), so these
# compose with every other overlay instead of being built from a second,
# un-overlaid nixpkgs.
{ inputs, pkgs, ... }:
{
  _2048 = pkgs.callPackage ./2048 { stdenv = pkgs.gcc14Stdenv; };
  agentsview = pkgs.callPackage ./agentsview { };
  maple-mono-custom = pkgs.callPackage ./maple-mono { inherit inputs; };
  pixelitos = pkgs.callPackage ./pixelitos { };
  pomo = pkgs.callPackage ./pomo { };
}
