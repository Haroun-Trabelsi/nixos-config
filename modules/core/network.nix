{ pkgs, ... }:
{
  networking = {
    # Deliberately constant across both machines. The disk moves between them,
    # and a hostname that changed per machine would churn SSH known_hosts and
    # break `nh os switch`, which resolves .#<hostname>.
    hostName = "desktop";
    networkmanager.enable = true;

    # Wired and WiFi are on the SAME LAN, so having both active at once gives the
    # box two links to one subnet: two default routes and two DNS sources. The
    # result is "connected but pages won't resolve" until one link is disabled —
    # the exact symptom (and manual workaround) observed. rp_filter is already
    # loose on this host, so relaxing routing won't help; the reliable fix is to
    # keep only one link active. This dispatcher disconnects WiFi whenever a wired
    # connection is up and reconnects it when the cable is unplugged. Ethernet is
    # preferred; WiFi is the automatic fallback.
    #
    # It uses `device disconnect` (a RUNTIME-only block), NOT `radio wifi off`:
    # the radio-off flag is saved to /var/lib/NetworkManager and would leave a
    # later cable-free boot with no WiFi at all. `device disconnect` clears on
    # reboot, so WiFi always auto-reconnects when no cable is present.
    # (To prefer WiFi instead, swap the disconnect/connect branches below.)
    networkmanager.dispatcherScripts = [
      {
        type = "basic";
        source = pkgs.writeShellScript "wifi-wired-exclusive" ''
          export LC_ALL=C
          nmcli=${pkgs.networkmanager}/bin/nmcli

          # Only react to interface up/down transitions.
          case "$2" in
            up | down) ;;
            *) exit 0 ;;
          esac

          # Locate the WiFi device (TYPE exactly "wifi", not "wifi-p2p").
          wifidev=$("$nmcli" -t -f DEVICE,TYPE device status \
            | ${pkgs.gnugrep}/bin/grep -m1 ':wifi$' \
            | ${pkgs.coreutils}/bin/cut -d: -f1)
          [ -n "$wifidev" ] || exit 0

          if "$nmcli" -t -f TYPE,STATE device status \
               | ${pkgs.gnugrep}/bin/grep -qx 'ethernet:connected'; then
            "$nmcli" device disconnect "$wifidev" || true
          else
            "$nmcli" device connect "$wifidev" || true
          fi
        '';
      }
    ];

    nameservers = [
      "8.8.8.8"
      "8.8.4.4"
      "1.1.1.1"
    ];
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22
        80
        443
        59010
        59011
      ];
      allowedUDPPorts = [
        59010
        59011
      ];
    };
  };

  environment.systemPackages = with pkgs; [ networkmanagerapplet ];
}
