{ pkgs, ... }:
{
  services = {
    gvfs.enable = true;

    gnome = {
      # tinysparql (Tracker) is a filesystem indexer. This root lives on a
      # USB-attached SSD, where background indexing is the worst possible I/O
      # pattern — it keeps the link active and the package out of deep C-states.
      # Nothing in this config queries it.
      tinysparql.enable = false;
      gnome-keyring.enable = true;
    };

    dbus.enable = true;
    fstrim.enable = true;

    # needed for GNOME services outside of GNOME Desktop
    dbus.packages = with pkgs; [
      gcr
      gnome-settings-daemon
    ];

    logind.settings.Login = {
      # don’t shutdown when power button is short-pressed
      HandlePowerKey = "ignore";

      # ignore lid close when docked/external monitor conected
      HandleLidSwitchDocked = "ignore";
    };

    udisks2.enable = true;
  };

  # disable NetworkManager-wait-online — not needed on desktops
  systemd.services.NetworkManager-wait-online.enable = false;

  # TPM SRK setup fails ("Object is remote") on this machine — stale persistent
  # data in the TPM doesn't match what systemd expects. We don't use TPM-based
  # disk unlock or sealed secrets, so disable the unit to keep activation clean.
  systemd.services.systemd-tpm2-setup.enable = false;

  # nsncd gets dragged up and down repeatedly during early boot, because
  # nss-lookup.target / nss-user-lookup.target are stopped and restarted as the
  # network settles (interface rename, timesyncd reconfiguring). With
  # Restart=always and systemd's default limit of 5 starts in 10 s it trips
  # start-limit-hit and stays dead for the rest of the boot.
  #
  # That is not cosmetic: on 2026-09-07 it left greetd unable to resolve the
  # user at all — PAM logged "check pass; user unknown" for every attempt, so no
  # password could work. Disabling the rate limit lets it settle instead.
  systemd.services.nscd.startLimitIntervalSec = 0;

  # limit journal size so journal-flush is fast
  services.journald.extraConfig = ''
    SystemMaxUse=100M
  '';
}
