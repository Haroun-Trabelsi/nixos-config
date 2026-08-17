{ pkgs, ... }:
let
  vesktopFlags = builtins.concatStringsSep " " [
    # Native Wayland rather than XWayland: no X translation layer, and it makes
    # the window match on app_id (which is what sway's rules.nix keys on).
    "--enable-features=UseOzonePlatform,WaylandWindowDecorations"
    "--ozone-platform=wayland"

    # Hardware video decode for calls and embedded video, via the iGPU's
    # fixed-function VDBOX. Same reasoning as thorium: software decode of a
    # 1080p stream is several watts on this part. Needs intel-media-driver and
    # LIBVA_DRIVER_NAME=iHD, both set up in the power phase.
    "--enable-features=VaapiVideoDecodeLinuxGL,AcceleratedVideoDecodeLinuxGL"

    # Discord animates constantly (emoji, avatars, typing indicators) and will
    # happily render at the display refresh rate in the background.
    "--force-prefers-reduced-motion"
  ];

  vesktopWrapped = pkgs.symlinkJoin {
    name = "vesktop-wrapped";
    paths = [ pkgs.vesktop ];
    postBuild = ''
      rm -f $out/bin/vesktop
      cat > $out/bin/vesktop <<EOF
      #!${pkgs.runtimeShell}
      exec ${pkgs.systemd}/bin/systemd-run --user --scope --slice=app-vesktop.slice \
        -- ${pkgs.vesktop}/bin/vesktop ${vesktopFlags} "\$@"
      EOF
      chmod +x $out/bin/vesktop
    '';
  };
in
{
  home.packages = [ vesktopWrapped ];

  # Same containment pattern as thorium: Discord is an Electron app with a
  # renderer that leaks over long sessions. Lower ceilings than the browser
  # because it is a chat client, not the main workload.
  #   MemoryHigh 1.5G — soft ceiling, kernel starts reclaiming here
  #   MemoryMax  2G   — hard cap, OOM-kills the offending process not the box
  #   MemorySwapMax 512M — without this a leaker balloons into swap and thrashes
  #     the USB-attached root disk instead of being killed
  systemd.user.slices."app-vesktop" = {
    Unit.Description = "Memory-capped slice for Vesktop";
    Slice = {
      MemoryHigh = "1500M";
      MemoryMax = "2G";
      MemorySwapMax = "512M";
    };
  };
}
