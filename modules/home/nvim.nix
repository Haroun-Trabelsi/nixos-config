{ ... }:
{
  programs.neovim = {
    enable = true;
    vimAlias = true;

    # Sets EDITOR (and VISUAL) to nvim for the whole session.
    #
    # Without this EDITOR was "nano", and there is no nano on this system — the
    # `nano` in zsh_alias.nix is a shell ALIAS pointing at nvim, and aliases do
    # not exist for anything that execs "$EDITOR". So `sops secrets/secrets.yaml`,
    # `git commit` without -m, `crontab -e` and friends all failed to launch an
    # editor at all.
    defaultEditor = true;
  };
}
