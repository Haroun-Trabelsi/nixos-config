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
  # No local Docker daemon. The redis/qdrant/mongodb containers were the single
  # largest power item left: with them up the machine drew ~15 W against a 4.22 W
  # idle, i.e. battery life fell from ~6.5 h to under 2 h.
  #
  # Socket activation meant they were not running at boot, but any stray `docker`
  # command woke the daemon and every container with a restart policy — which is
  # exactly what happened while auditing this.
  #
  # /var/lib/docker is left untouched, so no images, volumes or container data are
  # lost and re-enabling is one line. Run these services on a remote host and
  # reach it over the tailnet:
  #   docker context create remote --docker host=ssh://user@host
  #   docker context use remote
  users.users.${username} = {
    isNormalUser = true;
    description = "${username}";
    extraGroups = [
      # "docker" dropped with the local daemon — the group only grants access to
      # a socket that no longer exists.
      # "i2c" dropped along with hardware.i2c/ddcci — see modules/core/hardware.nix
      "networkmanager"
      "wheel"
    ];
    shell = pkgs.zsh;
  };
  nix.settings.allowed-users = [ "${username}" ];
}
