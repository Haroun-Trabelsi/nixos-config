{
  description = "Haroun's nixos configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/NUR";

    # Pinned ONLY to supply zed-editor, overlaid in modules/core/nixpkgs.nix.
    # The main nixpkgs (nixos-unstable) currently carries Zed 0.229.0, and Zed's
    # server no longer publishes a zed-remote-server asset for a release that
    # old — so `zed --ssh` fails with "not found in 0.229.0" and remote
    # development is impossible. This rev has 1.9.0.
    #
    # Deliberately a separate input rather than bumping nixpkgs: the blast radius
    # of a full unstable update right after the sway/power migration is the whole
    # system, and everything else here is measured and verified as-is.
    # Revisit (and drop this input) once nixos-unstable catches up past 1.9.0.
    nixpkgs-zed.url = "github:NixOS/nixpkgs/d407951447dcd00442e97087bf374aad70c04cea";

    # Restored for the desktop specialisation, which runs Hyprland + noctalia.
    #
    # PINNED to the exact revisions this desktop last ran (from the pre-migration
    # lock), NOT the latest. Four months of upstream drift had already renamed
    # `programs.noctalia-shell` to `programs.noctalia`, and Hyprland changes its
    # config syntax often — tracking HEAD would mean rewriting a 289-line shell
    # config and 400 lines of compositor settings to chase upstream, when the
    # goal here is simply to reproduce a desktop that worked.
    #
    # Unpin deliberately, one at a time, when you actually want to update.
    #
    # No hyprland flake input: nixpkgs' hyprland is used instead. The flake
    # input built from source (no usable binary cache for a non-trusted user),
    # which froze the machine. nixpkgs' build comes from cache.nixos.org.

    noctalia-shell = {
      url = "github:noctalia-dev/noctalia-shell/761869a561548874fe7e293b157fd7841576b367";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix/2bfdf55faf76fed12950b17d4af501e5a463607f";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    thorium.url = "github:Rishabh5321/thorium_flake";
    nix-gaming.url = "github:fufexan/nix-gaming";

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # gpakosz/.tmux ("Oh my tmux!"). Not a flake — just the two config files.
    # flake.lock pins the exact rev, so this is reproducible until you choose to
    # update it.
    oh-my-tmux = {
      url = "github:gpakosz/.tmux";
      flake = false;
    };

    maple-mono = {
      url = "github:subframe7536/maple-font/variable";
      flake = false;
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
