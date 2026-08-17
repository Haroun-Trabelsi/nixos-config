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
    docker
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
