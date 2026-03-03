{ pkgs, ... }:
{
  programs = {
    dconf.enable = true;
    zsh.enable = true;

    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      # pinentryFlavor = "";
    };

    appimage.enable = true;

    nix-ld.enable = true;
    nix-ld.libraries = with pkgs; [
      stdenv.cc.cc.lib
      zlib
      glib
      nspr
      nss
      dbus
      atk
      cups
      libdrm
      gtk3
      pango
      cairo
      libX11
      libXcomposite
      libXdamage
      libXext
      libXfixes
      libXrandr
      libxcb
      mesa
      mesa.drivers
      libgbm
      expat
      libxkbcommon
      alsa-lib
      at-spi2-atk
      at-spi2-core
      vulkan-loader
      libglvnd
    ];
  };
}
