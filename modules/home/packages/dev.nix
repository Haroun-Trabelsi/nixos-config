{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ## Lsp
    nixd # nix

    ## formating
    shfmt
    treefmt
    nixfmt

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
    docker-compose
    poetry
    mongodb-compass
    mongosh
    railway
    redis
    terraform
    ## Python
    python3
    python312Packages.ipython

  ];
}
