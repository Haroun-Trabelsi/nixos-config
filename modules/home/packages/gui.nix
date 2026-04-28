{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ## Multimedia
    audacity
    gimp
    media-downloader
    obs-studio
    pavucontrol
    soundwireserver
    video-trimmer

    ## Office
    libreoffice
    gnome-calculator

    ## Networking
    dynamips
    qbittorrent
    ubridge
    vpcs

    ## Utility
    dconf-editor
    gnome-disk-utility
    popsicle
    zenity
  ];
}
