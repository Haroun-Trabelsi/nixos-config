{ pkgs, ... }:
{
  home.packages = with pkgs; [
    kdePackages.dolphin
    kdePackages.qtsvg # icon rendering
    kdePackages.kio-fuse # remote file access
    kdePackages.kio-extras # thumbnails, network browsing
  ];
}
