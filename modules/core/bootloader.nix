{ pkgs, lib, inputs, ... }:
{
  # Lanzaboote (Secure Boot) lives HERE, in the shared layer, not in a
  # machine-specific module. There is one ESP and one bootloader install for both
  # machines: if a laptop-only rebuild ran the stock systemd-boot installer it
  # would drop an unsigned systemd-bootx64.efi over the signed one, and the
  # desktop would then fail Secure Boot and need a firmware trip to recover.
  #
  # Signing is a no-op on a machine with Secure Boot off, so this is harmless on
  # the laptop. The keys live at /var/lib/sbctl on the shared root, which is why
  # rebuilding on the laptop still produces UKIs the desktop will accept.
  imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

  boot = {
    loader = {
      systemd-boot.enable = lib.mkForce false; # replaced by lanzaboote
      efi.canTouchEfiVariables = true;
      # 5, not 10: the desktop specialisation's initrd carries the NVIDIA GSP
      # firmware (~125 MiB vs 43 MiB, see machines/desktop/nvidia.nix), and on
      # linuxPackages_latest most updates mint a new one. Ten of those overflow
      # the 1 GiB ESP. Matches nh's `--keep 5` in nh.nix.
      systemd-boot.configurationLimit = 5;

      # Fallback only. Under Lanzaboote this value is just the default feeding
      # boot.lanzaboote.settings.timeout, which is overridden to "menu-force"
      # below. This option is typed `null or signed integer`, so "menu-force"
      # cannot be expressed here.
      #
      # Do NOT set this to null: for systemd-boot that omits the line entirely,
      # and loader.conf(5) says an unset timeout means 0 — "no menu is shown and
      # the default entry will be booted immediately".
      timeout = 10;

      # The kernel cmdline editor lets anyone at the keyboard append
      # `init=/bin/sh` for a root shell. That is a Secure Boot bypass, and with
      # displayManager autoLogin there is no password gate in front of it.
      systemd-boot.editor = false;

      # The default 80x25 console fits ~20 lines. With configurationLimit = 5
      # plus a `desktop` specialisation entry per generation the list would
      # scroll off; `max` picks the largest mode the firmware offers.
      systemd-boot.consoleMode = "max";
    };

    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";

      # Always show the generation list, no countdown, no key held down.
      # loader.conf(5): "menu-force" disables the timeout while always showing
      # the menu. Set here rather than via boot.loader.timeout because
      # lanzaboote.settings is a freeform attrset written straight into
      # loader.conf, so unlike the typed option it accepts the string.
      settings.timeout = "menu-force";
    };

    # Kernel chatter stays hidden (loglevel, consoleLogLevel below), but systemd's
    # "[  OK  ] Started ..." lines are deliberately shown. "quiet" and
    # rd.systemd.show_status=false used to hide them too, which left the tower on
    # a black screen for 6-10 s between the NVIDIA driver taking the display and
    # Hyprland drawing. It looked hung, and a Ctrl+Alt+F3 pressed in that gap
    # (after greetd opened the session on tty1, before Hyprland took it) started
    # Hyprland on a background VT: a black screen that no VT switch could
    # recover, only a hard reset. Seen in the journal on 2026-09-24.
    kernelParams = [ "loglevel=3" "rd.udev.log_level=3" "udev.log_priority=3" ];
    consoleLogLevel = 0;
    initrd.verbose = false;

    kernelPackages = pkgs.linuxPackages_latest;

    # Kept even though the four hardcoded NTFS mounts are gone, so udisks2 can
    # still mount NTFS drives on demand when they are plugged in.
    supportedFilesystems = [ "ntfs" ];
  };

  environment.systemPackages = [ pkgs.sbctl ]; # Secure Boot key management
}
