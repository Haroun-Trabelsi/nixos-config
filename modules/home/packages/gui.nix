{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ## Multimedia
    audacity
    gimp
    linux-wallpaperengine
    media-downloader
    obs-studio
    pavucontrol
    soundwireserver
    video-trimmer
    vlc

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
