{ pkgs, inputs, ... }:

let
  thoriumPkg = inputs.thorium.packages."x86_64-linux".thorium-avx2;
  thoriumFlags = builtins.concatStringsSep " " [
    "--force-dark-mode"
    "--enable-features=WebContentsForceDark"
    # Stop WebRTC from lowering the system mic volume on detected clipping
    # (loud sounds / claps / bumps). Disables Chromium's AGC volume control.
    "--disable-features=WebRtcAllowInputVolumeAdjustment"
    "--gtk-version=4"
  ];

  # Wrap the binary itself so the flags apply no matter how thorium is
  # launched (shell, alias, session restore via --restart, etc.) — the
  # .desktop entry alone isn't enough.
  thoriumWrapped = pkgs.symlinkJoin {
    name = "thorium-wrapped";
    paths = [ thoriumPkg ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/thorium --add-flags "${thoriumFlags}"
    '';
  };
in
{
  home.packages = [ thoriumWrapped ];

  xdg.desktopEntries.thorium = {
    name = "Thorium";
    exec = "thorium ${thoriumFlags} %U";
    icon = "chromium"; # Papirus supports this
    terminal = false;
    categories = [
      "Network"
      "WebBrowser"
    ];
    mimeType = [
      "text/html"
      "application/xhtml+xml"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
      "x-scheme-handler/ftp"
    ];
  };
  xdg.desktopEntries.advancedNetwork = {
    name = "Advanced Network Configuration";
    exec = "nm-connection-editor";
    icon = "network-workgroup"; # well-supported in Papirus
    terminal = false;
    categories = [
      "Settings"
      "Network"
    ];
  };
}
