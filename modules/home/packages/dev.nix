{ pkgs, config, ... }:
{
  # agentsview ships a self-updater that would try to write into the Nix store.
  # The store is read-only, so the check only ever produces a failed nag.
  home.sessionVariables.AGENTSVIEW_DISABLE_UPDATE_CHECK = "1";

  # npm's default global prefix is the (read-only) Nix store, so `npm i -g`
  # fails. Point it at a writable dir under $HOME and put its bin on PATH, so
  # self-updating npm CLIs that aren't in nixpkgs (e.g. the Salesforce CLI,
  # `@salesforce/cli` -> `sf`) can be installed and update themselves.
  home.sessionVariables.NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.npm-global";
  # /usr/local/bin is not on NixOS's PATH by default. It holds the Coder CLI,
  # installed imperatively by coder.com's install script (a 421 MB static Go
  # binary at /usr/local/bin/coder — it runs fine without nix-ld).
  #
  # APPENDED via sessionVariablesExtra, not home.sessionPath: home-manager
  # PREPENDS sessionPath ahead of $PATH, which would let anything dropped into
  # /usr/local/bin silently shadow a Nix-store binary of the same name. Appending
  # means the store always wins and this is a fallback only.
  #
  # Two caveats that come with living outside Nix: it is not reproducible (a
  # fresh install of this flake will not have the binary), and it is never
  # garbage-collected or rebuilt when nixpkgs moves.
  #
  # nixpkgs does package coder, but at 2.33.9 against the 2.36.0 mainline
  # installed here. Coder is version-sensitive between CLI and deployment, so
  # the upstream installer is the right call while that gap exists — switch to
  # `pkgs.coder` and drop this once the versions line up.
  home.sessionVariablesExtra = ''
    export PATH="$PATH:/usr/local/bin"
  '';

  home.sessionPath = [ "${config.home.homeDirectory}/.npm-global/bin" ];

  home.packages = with pkgs; [
    ## Lsp
    nixd # nix

    ## formating
    shfmt
    treefmt
    nixfmt

    ## terminal
    tmux

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

  ];
}
