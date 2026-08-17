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

  # limit journal size so journal-flush is fast
  services.journald.extraConfig = ''
    SystemMaxUse=100M
  '';
}
