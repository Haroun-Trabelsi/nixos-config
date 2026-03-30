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
    gns3-gui
    gns3-server

    ## Utility
    dconf-editor
    gnome-disk-utility
    popsicle
    zenity
  ];
}
