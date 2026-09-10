{
  config,
  lib,
  inputs,
  username,
  ...
}:
# Root on tmpfs: state survives a reboot only if it is declared here.
#
# WHY: secrets/RECOVERY.md exists because untracked state is invisible until the
# disk dies. This inverts that — anything undeclared is gone at the next reboot,
# so you find out immediately instead of in two years when it matters.
#
# ─────────────────────────────────────────────────────────────────────────────
# THIS IS OFF BY DEFAULT ON REAL HARDWARE. Committing it changes nothing.
#
# It is also, contrary to how "erase your darlings" usually reads, NON-
# DESTRUCTIVE to adopt here, which is what makes it safe to try with one disk:
#
#   * The ext4 partition is not reformatted and nothing moves. It simply mounts
#     at /persist instead of /. /nix is already on it, so /persist/nix IS the
#     existing store — a bind mount, not a copy.
#   * Undeclared paths become INVISIBLE, not deleted. Everything currently at /
#     is still on that partition under /persist, so a forgotten path is
#     recoverable by looking there.
#   * Rollback works. An older generation mounts the same unchanged partition at
#     / and boots exactly as before, because the on-disk layout never changed.
#     That is the opposite of the usual impermanence risk profile.
#
# The genuinely destructive version — wiping the persist root on every boot via
# a btrfs snapshot rollback — is NOT what this does, and should not be added
# until the persist list has been proven over weeks rather than hours.
# ─────────────────────────────────────────────────────────────────────────────
let
  cfg = config.impermanence;

  # Mounts for the throwaway VM disk. /persist cannot keep pointing at the real
  # SSD's UUID there — that device does not exist in a VM.
  #
  # This list is the COMPLETE set of mounts in the VM, not an addition to them:
  # qemu-vm.nix does `fileSystems = mkVMOverride cfg.fileSystems`, replacing the
  # whole attrset. So /boot, the /nix bind and the /home bind all disappear in
  # the VM — /nix is replaced by QEMU's own 9p+overlay store, which is what you
  # want, and /home is deliberately left ephemeral:
  #
  #   a bind mount needs its SOURCE to exist, and /persist/home does not exist
  #   on a freshly autoFormat-ed disk. On real hardware it exists already,
  #   because it IS today's /home — so the bind works there and cannot work
  #   here. Faking it would test something the real machine never does.
  #
  # The VM therefore validates: tmpfs root, /persist mounting and formatting,
  # and the environment.persistence bind-mounts. It does not validate the /home
  # strategy, which needs no validation — it is one bind of an existing tree.
  vmMounts = {
    "/" = {
      device = "none";
      fsType = "tmpfs";
      options = [
        "defaults"
        "size=2G"
        "mode=755"
      ];
    };
    "/persist" = {
      device = "/dev/vda";
      fsType = "ext4";
      autoFormat = true;
      neededForBoot = true;
    };
  };
in
{
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  options.impermanence.enable = lib.mkEnableOption ''
    root-on-tmpfs with an explicit persist list.

    Try it in a VM first — `nixos-rebuild build-vm --flake .#portable` turns this
    on automatically for the VM only, so the flag never has to be flipped on real
    hardware to see it work
  '';

  # mkMerge, because the vmVariant has to apply REGARDLESS of cfg.enable — it is
  # what turns impermanence on for the VM while real hardware stays off — and a
  # module with an explicit `config` block cannot also set config at top level.
  config = lib.mkMerge [
    {
      # ── Testing hook ─────────────────────────────────────────────────────
      # This proves the config BOOTS and mounts correctly. It does NOT prove the
      # persist list is complete: a fresh VM has no accumulated state to lose, so
      # nothing is missed by missing it. Completeness is what
      # scripts/recovery/audit-undeclared-state.sh is for, plus living with it on
      # real hardware where undeclared paths stay recoverable under /persist.
      virtualisation.vmVariant = {
        impermanence.enable = true;
        virtualisation.useDefaultFilesystems = false;
        virtualisation.fileSystems = vmMounts;

        # The NixOS defaults are -m 1024 -smp 1, which cannot host a 2 GiB
        # tmpfs root: tmpfs is RAM, so the root filesystem would be capped by
        # the VM's total memory and the session would OOM before you got to
        # look at a mount table. QEMU runs with accel=kvm:tcg, so this is real
        # virtualisation on /dev/kvm rather than emulation.
        virtualisation.memorySize = 4096;
        virtualisation.cores = 4;
        virtualisation.diskSize = 8192;
      };
    }

    (lib.mkIf cfg.enable {
      # Root is a 4 GiB tmpfs. That is RAM, and it holds only what is NOT
      # persisted — on both machines (22-23 GiB) that is comfortable, but it is
      # also the ceiling on how much junk one uptime can accumulate at /.
      fileSystems."/" = lib.mkForce {
        device = "none";
        fsType = "tmpfs";
        options = [
          "defaults"
          "size=4G"
          "mode=755"
        ];
      };

      # /nix is the store that / is built from, so it has to come up before
      # anything else can resolve. It already lives on the persist partition.
      fileSystems."/nix" = {
        device = "/persist/nix";
        fsType = "none";
        options = [
          "bind"
          "noatime"
        ];
        neededForBoot = true;
      };

      # /home is persisted WHOLESALE rather than path-by-path.
      #
      # Deliberate: the audit found ~55 undeclared entries in $HOME against
      # 66 GB of real data. A per-path home list would be a large permanent
      # maintenance tax for very little — the reproducibility win is in /var and
      # in dotfiles that belong in this repo, not in enumerating one user's home.
      fileSystems."/home" = {
        device = "/persist/home";
        fsType = "none";
        options = [ "bind" ];
        neededForBoot = true; # sops-nix reads the age key from here at activation
      };

      # ...with one exception, which is where the space actually is: ~/.cache was
      # 26 GB at audit time, plus 4.7 GB of ~/.npm. Both are disposable by
      # definition, so they get their own tmpfs and never reach the disk.
      fileSystems."/home/${username}/.cache" = {
        device = "none";
        fsType = "tmpfs";
        options = [
          "defaults"
          "size=8G"
          "mode=700"
          "uid=1000"
          "gid=100"
        ];
      };

      # State that MUST survive. Every entry is load-bearing; the comments say
      # how, because "why is this in the list" is the question you will have in
      # six months.
      environment.persistence."/persist" = {
        hideMounts = true;

        directories = [
          "/var/lib/sbctl" # Lanzaboote pkiBundle — losing it breaks Secure Boot
          "/var/lib/nixos" # uid/gid map — losing it renumbers users
          "/var/lib/NetworkManager" # saved connections, incl. WiFi PSKs
          "/var/lib/bluetooth" # pairings
          "/var/lib/alsa" # hardware.alsa.enablePersistence writes here
          "/var/lib/upower" # battery history, cited in machines/laptop
          "/var/lib/systemd" # random-seed, timers, coredumps
          "/var/lib/tailscale" # node identity
          "/var/lib/tlp" # laptop power state
          "/var/lib/OpenRGB" # tower lighting profiles
          "/var/lib/udisks2"
          "/var/lib/AccountsService"
          "/var/log" # journal — otherwise every boot starts blind
          "/var/tmp"
        ];

        files = [
          "/etc/machine-id" # journald and systemd identity across boots
        ];
      };

      # Not listed on purpose — all of it is state from services this config
      # does not enable, found by the audit script and totalling ~4.2 GB:
      #   flatpak (4.0 GB), libvirt, qemu, machines, portables, colord, cups,
      #   docker, ollama, lightdm, lightdm-data, plymouth,
      #   power-profiles-daemon
      # Delete those from /persist/var/lib rather than persisting them.
    })
  ];
}
