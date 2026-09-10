{ pkgs, ... }:
{
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    wireplumber.enable = true;

    alsa = {
      enable = true;
      support32Bit = true;
    };

    # PipeWire defaults to a single allowed graph rate of 48kHz, which forces
    # every 44.1kHz source (i.e. nearly all music) through the resampler. On the
    # ddHiFi USB DAC that resampling was audible as a constant broadband hiss —
    # a 44.1kHz sine played native is clean, the same sine resampled to 48k is
    # not. Listing the rates the DAC advertises natively lets the graph follow
    # the content instead, so 44.1k material reaches the hardware untouched.
    # Side effect: switching between 44.1k and 48k content can produce a brief
    # gap or pop while the graph re-clocks. That is expected.
    extraConfig.pipewire."10-clock-rates" = {
      "context.properties" = {
        "default.clock.allowed-rates" = [
          44100
          48000
          88200
          96000
          176400
          192000
        ];
        # Anything at a rate outside the list above still has to be resampled
        # (22.05k/32k video audio, for example).
        #
        # Was 10, a very long sinc filter that runs per-sample on every affected
        # stream. The allowed-rates list above already means 44.1k and 48k music
        # is never resampled at all, so quality 10 only ever applied to the odd
        # 32k video track — paying a continuous CPU cost on a battery-powered
        # machine for a case that is both rare and inaudible at 4 (the upstream
        # default). Raise it again if resampled audio ever sounds wrong.
        "resample.quality" = 4;
      };
    };

    extraConfig.pipewire-pulse."90-disable-cork" = {
      "pulse.cmd" = [
        {
          cmd = "unload-module";
          args = "module-role-cork";
        }
      ];
    };
  };

  # alsa-utils (amixer/alsactl) and the ALSA state store are shared; the
  # laptop's headphone-jack workaround that used them lives in
  # machines/laptop/audio.nix, and the tower's HDMI profile pin in
  # machines/desktop/tv-audio.nix.
  hardware.alsa.enablePersistence = true;
  environment.systemPackages = with pkgs; [ alsa-utils ];
}
