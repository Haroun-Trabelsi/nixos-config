{
  pkgs,
  inputs,
  username,
  host,
  ...
}:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];
  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    extraSpecialArgs = { inherit inputs username host; };
    users.${username} = {
      imports = [ ./../home ];
      home.username = "${username}";
      home.homeDirectory = "/home/${username}";
      home.stateVersion = "26.05";
      home.sessionVariables = {
        LD_LIBRARY_PATH = "/run/current-system/sw/share/nix-ld/lib";
      };
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
      "i2c"
      "networkmanager"
      "wheel"
    ];
    shell = pkgs.zsh;
  };
  nix.settings.allowed-users = [ "${username}" ];
}
