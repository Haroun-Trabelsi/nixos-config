{ pkgs, lib, ... }:
# Every *.sh in ./scripts becomes a package named after the file, minus the
# extension, and lands in home.packages.
#
# These used to be built with `pkgs.writeScriptBin (readFile ...)`, which copies
# the file verbatim: no interpreter from the store, and no declared runtime
# dependencies at all. Every one of them relied on whatever happened to be on
# $PATH, so a script bound to a keybind broke silently the moment a package left
# home.packages — and `toggle-mic.sh` shipped a typo'd shebang
# (`#/usr/bin/env bash`, no `!`), which is not a shebang, so the kernel refused
# it and the caller's shell fell back to running it under plain sh.
#
# Now each script gets a store-path interpreter and a PATH prefix built from the
# list below.
#
# PATH is PREPENDED, not replaced, and that is deliberate:
#
#   * The compositor CLIs must stay ambient. `swaymsg` comes from sway and
#     `hyprctl` from Hyprland, which are installed on ONE machine each — putting
#     either in this list would drag that compositor into the other machine's
#     closure, i.e. build Hyprland for the laptop. The scripts only ever run
#     inside a live session of one of them (wm.sh dispatches on which), so they
#     are guaranteed present. Same reasoning for fuzzel and wlsunset (laptop
#     only) and virsh/virt-viewer (libvirtd is not enabled on either machine).
#   * The scripts call each other — `wm`, `toggle-app` and `notify` are siblings
#     resolved through the user profile.
#
# So: declared tools win over the profile, and everything deliberately gated by
# machine stays resolvable.
let
  scriptDir = ./scripts;

  runtimeInputs = with pkgs; [
    bash
    coreutils # cat date basename dirname mkdir head sort cut tr wc whoami uname seq sleep mktemp touch rm id tty
    findutils # find
    gawk # awk
    gnugrep
    gnused
    gnutar # compress.sh / extract.sh
    ncurses # tput — ascii.sh, maxfetch.sh
    procps # pkill, ps, uptime
    util-linux # setsid — code-web.sh
    which # runbg.sh, wm.sh

    iproute2 # ss — code-web.sh port check
    jq
    libnotify # notify-send
    git # plan-view.sh
    glow # plan-view.sh renders the plan markdown
    tmux # code-web.sh
    tree # linear-plan.sh

    # Wayland tooling, all of it in modules/home/wayland-tools.nix and therefore
    # present on both machines.
    cliphist
    grim
    slurp
    swappy
    tesseract
    wf-recorder
    wl-clipboard

    brightnessctl # toggle-mic.sh drives the mic-mute LED
    swayosd # swayosd-client — toggle-mic.sh
    wireplumber # wpctl — toggle-mic.sh
  ];

  binPath = lib.makeBinPath runtimeInputs;

  mkScript =
    name:
    let
      base = lib.removeSuffix ".sh" name;
      lines = lib.splitString "\n" (builtins.readFile (scriptDir + "/${name}"));
      firstLine = builtins.head lines;

      # Matches a real shebang AND the typo'd `#/usr/bin/env bash`.
      isShebang = builtins.match "^#!?/.*" firstLine != null;
      isZsh = builtins.match ".*zsh.*" firstLine != null;

      body = lib.concatStringsSep "\n" (
        if isShebang then builtins.tail lines else lines
      );
      interpreter = if isZsh then "${pkgs.zsh}/bin/zsh" else "${pkgs.bash}/bin/bash";
    in
    {
      inherit name;
      value = pkgs.writeTextFile {
        name = base;
        executable = true;
        destination = "/bin/${base}";
        text = ''
          #!${interpreter}
          export PATH=${binPath}''${PATH:+:$PATH}
          ${body}
        '';
        meta.mainProgram = base;
      };
    };

  isRegular = name: type: type == "regular";
  shellScripts = builtins.filter (name: lib.hasSuffix ".sh" name) (
    builtins.attrNames (lib.filterAttrs isRegular (builtins.readDir scriptDir))
  );
in
{
  home.packages = builtins.attrValues (
    builtins.listToAttrs (map mkScript shellScripts)
  );
}
