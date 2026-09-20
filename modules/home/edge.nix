{ pkgs, ... }:

let
  # Edge is a Chromium fork (152.0.4191.66 at time of writing) and its own
  # wrapper already conditionally adds --ozone-platform-hint=auto,
  # --enable-wayland-ime=true and --wayland-text-input-version=3 when
  # NIXOS_OZONE_WL is set (modules/home/hyprland/variables.nix,
  # modules/core/wayland.nix). That conditional ALSO adds
  # --enable-features=WaylandWindowDecorations, and Chromium parses
  # --enable-features LAST-WINS (see below) — so our own --enable-features
  # below restates WaylandWindowDecorations rather than dropping it. This bit
  # nothing yet because it was never exercised until this flag was added.
  edgeFlags = builtins.concatStringsSep " " [
    # No forced dark mode, same reasoning as the old chromium.nix: Edge
    # follows the system GTK theme for its UI, and pages render as their
    # authors wrote them.
    #
    # There must only ever be ONE --enable-features: Chromium parses it
    # LAST-WINS, so a second one silently discards the first rather than
    # merging. WaylandWindowDecorations is Edge's own (see comment above);
    # the other two are VA-API (below).
    #
    # VA-API: without it Edge decodes video in software — ~6-12 W for 1080p60
    # on the laptop's Raptor Lake-P part, against 1-2 W on the iGPU's
    # fixed-function VDBOX. Needs intel-media-driver (modules/core/hardware.nix)
    # and LIBVA_DRIVER_NAME=iHD (machines/laptop/graphics.nix) — the flags alone
    # do nothing.
    #
    # Verify at edge://media-internals during playback: the decoder should name
    # a hardware one, not FFmpegVideoDecoder. If VP9 content green-screens, that
    # is the known iHD/Chromium interaction — narrow it per codec rather than
    # dropping the whole feature.
    "--enable-features=WaylandWindowDecorations,VaapiVideoDecodeLinuxGL,AcceleratedVideoDecodeLinuxGL"

    # Stop WebRTC from lowering the system mic volume on detected clipping
    # (loud sounds / claps / bumps). Disables Chromium's AGC volume control.
    "--disable-features=WebRtcAllowInputVolumeAdjustment"
    "--gtk-version=4"

    # --- Memory footprint ---
    # Tightened 2026-09-19: 6 tabs measured at ~5G resident, which the old
    # chromium.nix number (8, copied over unexamined) was never actually
    # bounding — process-per-site only merges SAME-site tabs, and 6 tabs across
    # 6 different sites just gets 6 separate renderers, under the limit, doing
    # nothing. 4 forces sharing once a normal session (a handful of distinct
    # sites) is open, trading a bit of cross-tab crash isolation for actually
    # capping renderer count at real-world tab counts here.
    #
    # The bigger lever for "6 tabs, only one or two actually active" is Edge's
    # own Efficiency Mode / sleeping tabs (edge://settings/system) — it evicts
    # a BACKGROUND tab's renderer memory almost entirely rather than merely
    # capping process count. That is profile state, one checkbox, ticked once;
    # it is not nix-managed for the same reason Memory Saver wasn't in
    # chromium.nix, and it is the fix that actually matches "few tabs, one
    # ballooning" rather than "many tabs, too many processes".
    "--renderer-process-limit=4"
    "--process-per-site"
  ];

  # Wrap the REAL package's binary (not our own joined copy) so Edge's own
  # ozone/wayland conditional above still runs, and our flags land after it —
  # same structure the old chromium.nix used.
  #
  # The wrapper launches the browser inside the app-edge.slice cgroup (defined
  # below) via a transient systemd scope. All child processes (renderers, GPU,
  # extensions) inherit the cgroup, so the slice's MemoryMax is a kernel-
  # enforced hard cap on the whole browser. Memory Saver / flags only bound
  # process *count*; they can't stop a single leaking tab.
  edgeWrapped = pkgs.symlinkJoin {
    name = "microsoft-edge-wrapped";
    paths = [ pkgs.microsoft-edge ];
    postBuild = ''
      rm $out/bin/microsoft-edge
      cat > $out/bin/microsoft-edge << 'EOF'
      #!${pkgs.runtimeShell}
      exec ${pkgs.systemd}/bin/systemd-run --user --scope --quiet --collect \
        --slice=app-edge.slice \
        -- ${pkgs.microsoft-edge}/bin/microsoft-edge ${edgeFlags} "$@"
      EOF
      chmod +x $out/bin/microsoft-edge
    '';
  };
in
{
  home.packages = [ edgeWrapped ];

  # UNLIKE chromium.nix, this DOES need a hand-written desktop entry.
  # nixpkgs' microsoft-edge derivation runs substituteInPlace on its own
  # microsoft-edge.desktop, hard-coding Exec to the ABSOLUTE store path of the
  # unwrapped binary (checked in nixpkgs: pkgs/by-name/mi/microsoft-edge).
  # Chromium's shipped desktop entry uses a relative `Exec=chromium`, which is
  # why wrapping the binary alone was enough there — PATH resolution did the
  # rest. Edge's absolute path bypasses PATH entirely, so anything launched
  # from a menu/launcher (not a shell) would run the unwrapped binary — no
  # cgroup cap, no VA-API, no memory limits — unless this entry overrides it.
  # home-manager's xdg.desktopEntries module builds this with `lib.hiPrio`
  # specifically to win the nix-profile priority conflict against the same
  # desktop-file id shipped inside edgeWrapped (from pkgs.microsoft-edge, still
  # carried through symlinkJoin), so this is the one that actually gets linked.
  xdg.desktopEntries.microsoft-edge = {
    name = "Microsoft Edge";
    genericName = "Web Browser";
    comment = "Access the Internet";
    exec = "microsoft-edge %U";
    icon = "microsoft-edge";
    terminal = false;
    startupNotify = true;
    mimeType = [
      "application/pdf"
      "application/rdf+xml"
      "application/rss+xml"
      "application/xhtml+xml"
      "application/xhtml_xml"
      "application/xml"
      "image/gif"
      "image/jpeg"
      "image/png"
      "image/webp"
      "text/html"
      "text/xml"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
    ];
    categories = [
      "Network"
      "WebBrowser"
    ];
    settings = {
      StartupWMClass = "microsoft-edge";
    };
  };

  # Memory budget for the whole browser. Tightened 2026-09-19 from chromium.nix's
  # inherited 6G/8G: those were sized for a busy multi-tab session on a 22G box
  # and never actually got exercised here, so a 6-tab session hitting ~5G
  # resident had another 1G of soft ceiling and 3G of hard cap left to run into
  # before either one did anything:
  #   * MemoryHigh 3G  — soft ceiling: kernel starts reclaiming/throttling here,
  #     idle-tab pages get pushed to swap before anything drastic happens. Below
  #     the ~5G a normal 6-tab session was observed at, deliberately: this
  #     should engage on an ordinary session, not only a runaway one.
  #   * MemoryMax  5G  — hard cap: on breach the kernel OOM-kills the largest
  #     process in the slice (in practice the leaking renderer → one crashed
  #     tab), the rest of the browser keeps running.
  #   * MemorySwapMax 2G — without this a leaker just balloons into the 17G
  #     swap and thrashes the disk instead of getting killed.
  # If a legitimate heavy session (many tabs, video calls, etc.) starts getting
  # throttled or losing a tab to the cap, raise these back up — they are a
  # response to one measured 6-tab/5G session, not a hard ceiling on the browser.
  systemd.user.slices."app-edge" = {
    Unit.Description = "Memory-capped slice for Microsoft Edge";
    Slice = {
      MemoryHigh = "3G";
      MemoryMax = "5G";
      MemorySwapMax = "2G";
    };
  };

  # PROFILE STATE, NOT NIX-MANAGED, same caveat as the extension list in
  # browser-policies.nix: neither Chromium nor Edge exposes an enterprise
  # policy for UI theme or vertical tabs — both are treated as pure end-user
  # preference, not something a managed/recommended policy can set. So unlike
  # fonts (a real, if undocumented, profile field patched directly 2026-09-19)
  # or extensions (a real forcelist policy), these two just live in
  # ~/.config/microsoft-edge/Default/Preferences with no way to declare them.
  # If the profile is ever reset (as it was migrating from Chromium), reapply
  # by hand:
  #   - Appearance: System default (not an explicit Light/Dark override) — the
  #     dark result then comes from gtk.nix's dconf color-scheme=prefer-dark,
  #     so it's derived from something nix DOES manage, rather than being its
  #     own independent setting to lose again.
  #   - Vertical tabs: on (the icon-only collapsed layout, not full-width).
  #
  # Unrelated to the browser, parked here since the Thorium era and moved
  # along with each rename (Thorium -> Chromium -> Edge) rather than given its
  # own file.
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
