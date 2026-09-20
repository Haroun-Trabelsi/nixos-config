{
  lib,
  pkgs,
  config,
  ...
}:
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

  home.activation.sshConfigRealFile =
    lib.hm.dag.entryAfter [ "linkGeneration" ]
      ''
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

    # Upstream ssh_config directive names (HostName, IdentityFile, ...), not the
    # old camelCase aliases: `programs.ssh.matchBlocks` and its `extraOptions`
    # escape hatch are both deprecated in favour of `settings`, which takes the
    # real directives directly. Booleans still render as yes/no.
    #
    # The attribute name is used as the `Host` pattern unless `header` is given.
    # These blocks keep short stable names and set `header` explicitly, because
    # the names are what any DAG ordering would refer to.
    settings = {
      github = {
        header = "Host github.com";
        HostName = "ssh.github.com";
        User = "git";
        Port = 443;
        IdentityFile = "~/.ssh/id_github";
        IdentitiesOnly = true;
      };

      # Coder workspaces. These blocks were written into ~/.ssh/config.d/coder by
      # `coder config-ssh` — untracked state that hardcoded
      # /usr/local/bin/coder, the imperatively-installed binary. Declared here
      # they point at pkgs.coder instead, so the ProxyCommand resolves to a store
      # path that is actually part of this system's closure.
      #
      # `coder config-ssh` will happily rewrite its own file again and shadow
      # these (config.d/* is included ABOVE the "*" block and ssh is
      # first-match-wins). Don't run it; if you must, delete
      # ~/.ssh/config.d/coder afterwards.
      #
      # StrictHostKeyChecking/UserKnownHostsFile are upstream's own settings:
      # workspaces are ephemeral and their host keys change on every rebuild, so
      # pinning them would mean a warning every time. Scoped to coder hosts only.
      coder-prefixed = {
        header = "Host coder.*";
        ConnectTimeout = "0";
        StrictHostKeyChecking = "no";
        UserKnownHostsFile = "/dev/null";
        LogLevel = "ERROR";
        ProxyCommand =
          "${pkgs.coder}/bin/coder --global-config ${config.xdg.configHome}/coderv2 "
          + "ssh --stdio --ssh-host-prefix coder. %h";
      };

      coder-suffixed = {
        header = "Host *.coder";
        ConnectTimeout = "0";
        StrictHostKeyChecking = "no";
        UserKnownHostsFile = "/dev/null";
        LogLevel = "ERROR";
      };

      # Last on purpose: ssh_config is first-match-wins, and home-manager emits
      # the "*" block after every other one for exactly that reason.
      "*" = {
        AddKeysToAgent = "1h";

        ControlMaster = "auto";
        ControlPath = "~/.ssh/control-%r@%h:%p";
        ControlPersist = "10m";

        ForwardAgent = false;
        Compression = false;
        ServerAliveInterval = 0;
        ServerAliveCountMax = 3;
        HashKnownHosts = false;
        UserKnownHostsFile = "~/.ssh/known_hosts";
      };
    };
  };

  services.ssh-agent.enable = true;

  # Create the drop-in directory. Without this the first `coder config-ssh` has
  # to create it itself, and it errors instead. Not managed by home-manager
  # beyond this marker, so the tools own their own files inside it.
  home.file.".ssh/config.d/.keep".text = "";
}
