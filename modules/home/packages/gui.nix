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
    vlc

    ## Office
    libreoffice
    gnome-calculator

    ## Networking
    dynamips
    ubridge
    vpcs

    ## Utility
    dconf-editor
    gnome-disk-utility
    popsicle
    zenity
  ];
}
