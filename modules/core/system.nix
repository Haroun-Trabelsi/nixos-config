{ pkgs, inputs, ... }:
{
  nix = {
    # Pin the flake registry and NIX_PATH to the exact nixpkgs this system was
    # built from. Without this, `nix run nixpkgs#foo`, `nix shell nixpkgs#foo`
    # and `,` (comma, enabled in packages/nix.nix) all resolve "nixpkgs"
    # against the UPSTREAM registry and fetch a different tree than flake.lock
    # — so an ad-hoc tool is a different build from the same-named package in
    # this config, and the answer changes with the calendar.
    registry.nixpkgs.flake = inputs.nixpkgs;
    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];

    # No nix-channels either: channels are the other unpinned path to a
    # different nixpkgs, and nothing here uses them.
    channel.enable = false;

    # A rebuild must never be able to take the desktop down with it.
    #
    # SCHED_IDLE means a build process only gets CPU when nothing else wants it,
    # so a twelve-way compile is something you can keep working through instead
    # of something you wait out. IO class idle matters at least as much here:
    # the store, the home directory and the 17 GiB swap partition are all on the
    # SAME portable USB SSD, so an unthrottled build starves the very device the
    # session needs to page anything back in — which is why this presents as a
    # hard freeze rather than as a machine that is merely busy.
    daemonCPUSchedPolicy = "idle";
    daemonIOSchedClass = "idle";

    settings = {
      auto-optimise-store = false;

      # Nothing capped parallelism before this, so the defaults applied:
      # max-jobs = "auto" (12 on the 7600X's 12 threads) and cores = 0 ("use
      # every core"). That is up to 12 derivations building at once, each free
      # to spawn 12 compilers — ~144 concurrent jobs, and a memory ceiling set
      # by whatever the linker happened to want. Any source build that slipped
      # past the substituters (the Hyprland case noted below, a Rust workspace)
      # would fill 22 GiB of RAM, spill into swap on the USB SSD, and lock the
      # machine.
      #
      # 4 x 3 keeps the worst case at 12 compile jobs — one per thread — and
      # bounds peak memory to four concurrent link steps rather than twelve.
      # Raise max-jobs for throughput on a machine you are not sitting at;
      # `nix build --max-jobs N --cores N` overrides both per invocation.
      max-jobs = 4;
      cores = 3;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      substituters = [
        "https://nix-community.cachix.org"
        # Restored with the Hyprland desktop. WITHOUT these, Hyprland and
        # noctalia have no binary cache and nix compiles Hyprland from source —
        # a huge C++ build that saturates every core and freezes the machine.
        "https://hyprland.cachix.org"
        "https://noctalia.cachix.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      ];
    };
  };

  # The CPU/IO caps above make a build polite; this is what stops it from
  # exhausting RAM. Build processes are children of nix-daemon and share its
  # cgroup, so the whole build tree is accounted here.
  #
  # Percentages rather than absolute sizes, deliberately: one SSD boots two
  # machines with different amounts of RAM, and "70%" is correct on both where
  # "16G" would be correct on neither.
  #
  # MemoryHigh is the load-bearing one — it throttles allocation and forces
  # reclaim, which is a slow build instead of a dead desktop. MemoryMax is only
  # a backstop against a genuine runaway; a build that hits it is OOM-killed and
  # fails, which is still a far better outcome than taking the session with it.
  systemd.services.nix-daemon.serviceConfig = {
    MemoryHigh = "70%";
    MemoryMax = "85%";
  };

  environment.systemPackages = with pkgs; [
    wget
    git
  ];

  time.timeZone = "Africa/Tunis";
  i18n.defaultLocale = "en_US.UTF-8";
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "26.05";
}
