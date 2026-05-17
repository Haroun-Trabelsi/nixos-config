{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    gnome-network-displays
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav
    gst_all_1.gst-vaapi
  ];

  networking.firewall = {
    allowedTCPPorts = [
      7236
      7250
    ];
    allowedUDPPorts = [
      7236
      5353
    ];
    allowedUDPPortRanges = [
      {
        from = 32768;
        to = 60999;
      }
    ];
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
}
