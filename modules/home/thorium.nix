{ pkgs, inputs, ... }:

let
  thoriumPkg = inputs.thorium.packages."x86_64-linux".thorium-avx2;
  thoriumFlags = builtins.concatStringsSep " " [
    "--force-dark-mode"
    "--enable-features=WebContentsForceDark"
    # Stop WebRTC from lowering the system mic volume on detected clipping
    # (loud sounds / claps / bumps). Disables Chromium's AGC volume control.
    "--disable-features=WebRtcAllowInputVolumeAdjustment"
    "--gtk-version=4"

    # Hardware video decode via VA-API. Without this Chromium decodes in
    # software: ~6-12 W for 1080p60 on this Raptor Lake-P part, against 1-2 W on
    # the iGPU's fixed-function VDBOX. Needs intel-media-driver installed
    # (modules/core/hardware.nix) and LIBVA_DRIVER_NAME=iHD
    # (machines/laptop/graphics.nix) — the flags alone do nothing.
    #
    # Verify at thorium://media-internals during playback: the decoder should
    # name a hardware one, not FFmpegVideoDecoder. If VP9 content green-screens,
    # that is the known iHD/Chromium interaction — narrow it per codec rather
    # than dropping the whole feature.
    "--enable-features=VaapiVideoDecodeLinuxGL,AcceleratedVideoDecodeLinuxGL"

    # --- Memory footprint ---
    # By default Chromium sizes its renderer-process pool off total RAM, which
    # on a 22G box is very high, so a busy session can balloon toward ~10G.
    # These two flags bound process proliferation (the main memory driver) at
    # the cost of a little cross-tab crash isolation:
    #   * renderer-process-limit: hard cap on renderer processes; extra tabs
    #     share existing renderers instead of each spawning their own. Raise
    #     this (e.g. 12) if heavy multi-tab browsing starts feeling janky.
    #   * process-per-site: all tabs of the SAME site (scheme+eTLD+1) reuse one
    #     renderer, so N Google tabs cost one process instead of N. Cross-site
    #     isolation is preserved; only same-site tabs share a fate.
    # The real root-cause fix is Memory Saver (thorium://settings/performance),
    # which hibernates idle tabs — enable that in the UI, it persists in the profile.
    "--renderer-process-limit=8"
    "--process-per-site"
  ];

  # Wrap the binary itself so the flags apply no matter how thorium is
  # launched (shell, alias, session restore via --restart, etc.) — the
  # .desktop entry alone isn't enough.
  #
  # The wrapper also launches the browser inside the app-thorium.slice cgroup
  # (defined below) via a transient systemd scope. All child processes
  # (renderers, GPU, extensions) inherit the cgroup, so the slice's MemoryMax
  # is a kernel-enforced hard cap on the whole browser. Memory Saver / flags
  # only bound process *count*; they can't stop a single leaking tab.
  thoriumWrapped = pkgs.symlinkJoin {
    name = "thorium-wrapped";
    paths = [ thoriumPkg ];
    postBuild = ''
      rm $out/bin/thorium
      cat > $out/bin/thorium << 'EOF'
      #!${pkgs.runtimeShell}
      exec ${pkgs.systemd}/bin/systemd-run --user --scope --quiet --collect \
        --slice=app-thorium.slice \
        -- ${thoriumPkg}/bin/thorium ${thoriumFlags} "$@"
      EOF
      chmod +x $out/bin/thorium
    '';
  };
in
{
  home.packages = [ thoriumWrapped ];

  # Memory budget for the whole browser (22G box):
  #   * MemoryHigh 6G  — soft ceiling: kernel starts reclaiming/throttling here,
  #     idle-tab pages get pushed to swap before anything drastic happens.
  #   * MemoryMax  8G  — hard cap: on breach the kernel OOM-kills the largest
  #     process in the slice (in practice the leaking renderer → one "Aw, Snap"
  #     tab), the rest of the browser keeps running.
  #   * MemorySwapMax 2G — without this a leaker just balloons into the 17G
  #     swap and thrashes the disk instead of getting killed.
  systemd.user.slices."app-thorium" = {
    Unit.Description = "Memory-capped slice for Thorium";
    Slice = {
      MemoryHigh = "6G";
      MemoryMax = "8G";
      MemorySwapMax = "2G";
    };
  };

  xdg.desktopEntries.thorium = {
    name = "Thorium";
    # Plain `thorium` resolves to the wrapper above, which already appends the
    # flags and enters the memory-capped slice — no need to repeat them here.
    exec = "thorium %U";
    icon = "chromium"; # Papirus supports this
    terminal = false;
    categories = [
      "Network"
      "WebBrowser"
    ];
    mimeType = [
      "text/html"
      "application/xhtml+xml"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
      "x-scheme-handler/ftp"
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
