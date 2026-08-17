{
  pkgs,
  inputs,
  username,
  ...
}:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];
  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    extraSpecialArgs = { inherit inputs username; };
    users.${username} = {
      imports = [ ./../home ];
      home.username = "${username}";
      home.homeDirectory = "/home/${username}";
      home.stateVersion = "26.05";
      # NOTE: do NOT set a global LD_LIBRARY_PATH to the nix-ld lib dir. It
      # overrides every binary's own RPATH and forces proper Nix programs (e.g.
      # hyprctl) onto nix-ld's older libstdc++, breaking them with GLIBCXX
      # errors. nix-ld works via its own loader + NIX_LD_LIBRARY_PATH, which
      # programs.nix-ld sets automatically — no LD_LIBRARY_PATH needed.
      programs.home-manager.enable = true;
    };
    backupFileExtension = "hm-backup";
  };
  virtualisation.docker.enable = true;

  # don't start docker at boot — socket activation starts it on first use
  systemd.services.docker.wantedBy = pkgs.lib.mkForce [ ];
  users.users.${username} = {
    isNormalUser = true;
    description = "${username}";
    extraGroups = [
      "docker"
      # "i2c" dropped along with hardware.i2c/ddcci — see modules/core/hardware.nix
      "networkmanager"
      "wheel"
    ];
    shell = pkgs.zsh;
  };
  nix.settings.allowed-users = [ "${username}" ];
}
