{ pkgs, ... }:
{
  home.packages = with pkgs; [
    claude-code
    nodejs_24
    docker
    docker-compose
    poetry
  ];
}
