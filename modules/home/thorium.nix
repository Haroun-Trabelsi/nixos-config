{ pkgs, inputs, ... }:

let
  thoriumPkg = inputs.thorium.packages."x86_64-linux".thorium-avx2;
in
{
  home.packages = [ thoriumPkg ];

  xdg.desktopEntries.thorium = {
    name = "Thorium";
    exec = "thorium";
    icon = "chromium"; # Papirus supports this
    terminal = false;
    categories = [
      "Network"
      "WebBrowser"
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
