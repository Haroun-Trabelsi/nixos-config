{ ... }:
{
  programs.ssh = {
    enable = true;

    enableDefaultConfig = false;

    # home-manager renders ~/.ssh/config as a read-only symlink into the Nix
    # store, so tools that write their own host blocks into it fail outright —
    # `coder config-ssh` is the one that prompted this, but Tailscale and cloud
    # CLIs do the same thing.
    #
    # These Include lines are emitted at the TOP of the generated config, which
    # matters: ssh_config is first-match-wins, so an included Host block must
    # appear before the "*" block below to be able to override it.
    #
    # A glob that matches nothing is not an error in ssh, so this is safe when
    # the directory is empty. Point such tools at a file inside it:
    #   coder config-ssh --ssh-config-file ~/.ssh/config.d/coder
    includes = [ "config.d/*" ];

    matchBlocks = {
      "*" = {
        addKeysToAgent = "1h";

        controlMaster = "auto";
        controlPath = "~/.ssh/control-%r@%h:%p";
        controlPersist = "10m";

        forwardAgent = false;
        compression = false;
        serverAliveInterval = 0;
        serverAliveCountMax = 3;
        hashKnownHosts = false;
        userKnownHostsFile = "~/.ssh/known_hosts";
      };

      github = {
        host = "github.com";
        hostname = "ssh.github.com";
        user = "git";
        port = 443;
        identityFile = "~/.ssh/id_github";
        identitiesOnly = true;
      };
    };
  };

  services.ssh-agent.enable = true;

  # Create the drop-in directory. Without this the first `coder config-ssh` has
  # to create it itself, and it errors instead. Not managed by home-manager
  # beyond this marker, so the tools own their own files inside it.
  home.file.".ssh/config.d/.keep".text = "";
}
