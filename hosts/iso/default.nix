{ pkgs, self, inputs, modulesPath, ... }:
let
  disko = inputs.disko.packages.${pkgs.system}.disko;
  installScript = pkgs.writeShellScriptBin "install-nixos" (builtins.readFile ./install.sh);
in
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    git
    gum
    jq
    age
    sops
    disko
    installScript
  ];

  # Bake the flake source into the ISO at /etc/nixos-config
  environment.etc."nixos-config".source = self;

  # Nix flakes support in the live ISO
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
