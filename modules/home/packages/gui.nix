{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ## Multimedia
    audacity
    gimp
    media-downloader
    obs-studio
    pavucontrol
    # GNOME Camera. Goes through the PipeWire camera portal rather than opening
    # /dev/video0 directly, so it shares the webcam with OBS/Discord instead of
    # locking them out of it.
    snapshot
    soundwireserver
    video-trimmer
    vlc

    ## Editors
    # Native (Rust/GPUI), not Electron — the point of Win+C. VS Code stays
    # installed for when you want its extension ecosystem.
    zed-editor

    ## Office
    libreoffice
    onlyoffice-desktopeditors
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
