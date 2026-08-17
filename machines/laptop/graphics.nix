{ lib, config, ... }:
lib.mkIf (config.machine.profile == "laptop") {
  # Intel iGPU VA-API. The driver itself is installed in modules/core/hardware.nix
  # (intel-media-driver + vpl-gpu-rt); this points libva at it.
  #
  # Before this, LIBVA_DRIVER_NAME was "nvidia" on both machines and no
  # iHD_drv_video.so existed anywhere, so browser video decode ran 100% in
  # software. On Raptor Lake-P that is 6-12 W for 1080p60 against 1-2 W on the
  # fixed-function VDBOX — the largest single item in the whole power plan for a
  # workload that includes watching video.
  #
  # This has to be a NixOS sessionVariable rather than home.sessionVariables:
  # the display manager execs the compositor directly and never sources
  # hm-session-vars.sh. environment.sessionVariables lands in /etc/pam/environment,
  # which pam_env does apply.
  #
  # Verify with: vainfo   (expect VAProfileH264High and VAProfileVP9Profile0)
  #              sudo intel_gpu_top   (Video engine busy% non-zero during playback)
  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";
}
