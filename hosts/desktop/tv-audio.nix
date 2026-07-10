{ pkgs, ... }:
let
  # The RTX 5060 Ti's HDA codec (PCI 01:00.1) drives two outputs: the TV (HDMI,
  # has speakers) and an HP monitor (DisplayPort, no speakers). PipeWire's ACP
  # exposes only ONE HDMI stereo output as a sink at a time, and WirePlumber kept
  # selecting the monitor's output ("Digital Stereo (HDMI 2)"), leaving the TV
  # with no sink at all — so the TV speakers were never recognized.
  #
  # Profile index 1 ("output:hdmi-stereo") is the card's first HDMI output = the
  # TV; index 2 ("...-extra1" / "HDMI 2") is the speakerless monitor. This service
  # pins the card to the TV output once WirePlumber is up, re-asserting a few
  # times to win the startup race with WirePlumber's own profile restore.
  pinTvAudio = pkgs.writeShellScript "nvidia-tv-audio-profile" ''
    set -u
    card="alsa_card.pci-0000_01_00.1"
    profile=1
    applied=0
    i=0

    while [ "$i" -lt 30 ]; do
      i=$((i + 1))
      dev=$(${pkgs.pipewire}/bin/pw-cli ls Device 2>/dev/null \
        | ${pkgs.gawk}/bin/awk -v n="$card" \
            '/^[[:space:]]*id /{id=$2; gsub(/,/,"",id)} $0 ~ n {print id; exit}')
      if [ -n "$dev" ]; then
        ${pkgs.wireplumber}/bin/wpctl set-profile "$dev" "$profile" >/dev/null 2>&1 \
          && applied=$((applied + 1))
        [ "$applied" -ge 5 ] && exit 0
      fi
      ${pkgs.coreutils}/bin/sleep 1
    done
    exit 0
  '';
in
{
  systemd.user.services.nvidia-tv-audio-profile = {
    description = "Pin NVIDIA HDMI audio to the TV output (not the speakerless monitor)";
    wantedBy = [ "pipewire.service" ];
    after = [
      "pipewire.service"
      "wireplumber.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pinTvAudio;
    };
  };
}
