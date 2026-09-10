{ pkgs, config, ... }:
{
  # agentsview ships a self-updater that would try to write into the Nix store.
  # The store is read-only, so the check only ever produces a failed nag.
  home.sessionVariables.AGENTSVIEW_DISABLE_UPDATE_CHECK = "1";

  # npm's default global prefix is the (read-only) Nix store, so `npm i -g`
  # fails. Point it at a writable dir under $HOME for the odd throwaway install.
  #
  # It is NO LONGER on PATH. The only thing that lived there was the Salesforce
  # CLI, which is now pkgs.salesforce-cli (pinned to an upstream standalone build
  # with a published sha256), so nothing needs an untracked ~/.npm-global on PATH
  # to work — and leaving it there meant `npm i -g` could silently shadow a
  # store binary on the next shell.
  home.sessionVariables.NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.npm-global";

  # /usr/local/bin is NO LONGER appended to PATH either. It held exactly one
  # thing — the Coder CLI, dropped there by coder.com's install script — and that
  # is now pkgs.coder, pinned to 2.36.0 to match the deployment.
  #
  # Both of those were the config's last two "works on this machine only"
  # dependencies: a fresh install of this flake did not have either binary, and
  # neither was ever garbage-collected or rebuilt when nixpkgs moved.
  #
  # If you need an imperative escape hatch again, prefer `nix shell nixpkgs#foo`
  # or a one-off derivation over putting a mutable directory on PATH.

  home.packages = with pkgs; [
    ## Lsp
    nixd # nix

    ## formating
    shfmt
    treefmt
    nixfmt

    ## terminal
    tmux
    direnv # per-project env; was parked in the Hyprland module

    ## C / C++
    gcc
    stdenv.cc.cc.lib
    glib
    cmake
    gnumake
    valgrind
    llvmPackages_20.clang-tools

    # claude-code # installed via npm, nixpkgs version often lags behind
    nodejs_24
    google-cloud-sdk
    # Client only (no dockerd binary): the CLI is still needed to drive a REMOTE
    # daemon via `docker context`, which is the whole point of moving these
    # services off the laptop. pkgs.docker would ship the daemon too.
    docker-client
    sops
    docker-compose
    poetry
    mongodb-compass
    mongosh
    railway
    redis
    ngrok
    stripe-cli
    prometheus
    prometheus.cli # promtool — Prometheus rule/config linter (separate output from the server)
    terraform
    ## Python
    python3
    python312Packages.ipython

    ## Agent tooling
    agentsview # local session search + token/cost analytics for coding agents

    ## Pinned upstream release binaries (see pkgs/) — these replace what used to
    ## be an imperative installer plus a mutable directory on PATH.
    coder # 2.36.0, matching the Coder deployment this talks to
    salesforce-cli # sf / sfdx

  ];
}
