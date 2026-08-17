{
  description = "Haroun's nixos configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/NUR";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    thorium.url = "github:Rishabh5321/thorium_flake";
    nix-gaming.url = "github:fufexan/nix-gaming";
    nix-flatpak.url = "github:gmodena/nix-flatpak";

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    maple-mono = {
      url = "github:subframe7536/maple-font/variable";
      flake = false;
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    superfile.url = "github:yorukot/superfile";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin.url = "github:catppuccin/nix";
    catppuccin.inputs.nixpkgs.follows = "nixpkgs";

    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      # NOTE: do NOT make nixpkgs follow ours — nixpkgs 26.05 stdenv made
      # unpackPhase reject unnamed archives, which breaks lanzaboote's
      # pinned rust-overlay (rust-src-1.78.0 fetched without .tar.xz name).
    };
  };

  outputs =
    { nixpkgs, self, ... }@inputs:
    let
      username = "fantasy";
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      lib = nixpkgs.lib;

      # The single system config. Both machines boot this; the tower is a
      # specialisation inside it (see hosts/portable/specialisations.nix).
      portable = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [ ./hosts/portable ];
        specialArgs = {
          inherit self inputs username;
        };
      };
    in
    {
      nixosConfigurations = {
        # One config for one portable SSD. The base is the laptop; the AMD/NVIDIA
        # tower is a `specialisation` inside it with its own signed boot entry,
        # picked from the boot menu rather than by rebuilding first.
        #
        # There is no `host` specialArg any more: specialArgs are fixed per
        # nixosConfiguration and cannot vary per specialisation, so the machine
        # is a normal option (config.machine.profile / osConfig.machine.profile).
        portable = portable;

        # networking.hostName is still "desktop", and `nh os switch` resolves
        # .#<hostname>, so this alias keeps nh and `--flake .#desktop` working.
        desktop = portable;

        iso = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [ ./hosts/iso ];
          specialArgs = { inherit self inputs; };
        };
      };

      packages.${system}.iso = self.nixosConfigurations.iso.config.system.build.isoImage;
    };
}
