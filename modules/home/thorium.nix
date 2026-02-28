{ pkgs, inputs, ... }:

{
  home.packages = with pkgs; [
    # Thorium package from the flake input
    inputs.thorium.packages."x86_64-linux".thorium-avx2
  ];
}
