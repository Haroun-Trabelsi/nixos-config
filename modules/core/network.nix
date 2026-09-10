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

    # No `nameservers` override. It used to hardcode 8.8.8.8/8.8.4.4/1.1.1.1,
    # which takes precedence over whatever DHCP hands out — so on a captive
    # portal the sign-in redirect never resolves, and on a LAN with
    # split-horizon DNS internal names silently fail. That is the same
    # "connected but nothing resolves" class of failure the dispatcher script
    # above exists to prevent, just from the other direction.
    #
    # DHCP-provided DNS is used instead. If a network's resolver is genuinely
    # bad, override it per-connection (`nmcli con mod <name> ipv4.dns ...`)
    # rather than globally for every network this laptop ever joins.

    firewall = {
      enable = true;

      # 22/80/443 were open with nothing behind them: services.openssh is not
      # enabled anywhere in this config, and there is no web server. SSH here is
      # outbound only (client + agent), which needs no inbound port, and remote
      # nodes are reached over the tailnet — tailscale0 is a trusted interface in
      # modules/core/tailscale.nix, so enabling sshd later would still be
      # reachable there without reopening 22 to every coffee-shop network.
      #
      # 59010/59011 are SoundWire (pkgs.soundwireserver, packages/gui.nix),
      # which does need them inbound on both protocols.
      allowedTCPPorts = [
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
