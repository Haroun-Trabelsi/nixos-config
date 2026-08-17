{ lib, ... }:
{
  # home-manager normally symlinks ~/.ssh/config into the Nix store, where the
  # file is owned by root. OpenSSH accepts that (it explicitly allows uid 0 as
  # long as the file is not group/other-writable), but stricter clients do not —
  # Zed refuses to connect with "Bad owner or permissions on ~/.ssh/config"
  # because it insists the file be owned by the invoking user.
  #
  # So: redirect home-manager's generated file to ~/.ssh/config.hm, then copy it
  # into place as a real file owned by this user with mode 600. Overriding
  # `target` also stops home-manager managing ~/.ssh/config directly, which
  # avoids it fighting the copy and littering .hm-backup files on every switch.
  home.file.".ssh/config".target = ".ssh/config.hm";

  home.activation.sshConfigRealFile = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run install -m600 -T "$HOME/.ssh/config.hm" "$HOME/.ssh/config"
  '';

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
