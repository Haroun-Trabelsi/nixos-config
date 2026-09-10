{
  pkgs,
  lib,
  config,
  ...
}:
# Laptop-only audio quirk. This lived in modules/core/pipewire.nix, which meant
# it also ran on the tower — where `card=0`, numid 15 and the PCI path below are
# not this codec at all, so the service was poking at whatever card happened to
# enumerate first on an entirely different machine.
#
# The tower's counterpart is machines/desktop/tv-audio.nix.
let
  # The headset mic jack on this ALC256 is a "Phantom Jack" (no hardware sense),
  # so the kernel can't auto-switch the analog input route when headphones are
  # plugged in. The headphone OUTPUT jack does have real sense and switches
  # natively — this service mirrors that state onto the input side.
  micJackSwitcher = pkgs.writeShellScript "mic-jack-switcher" ''
    set -u

    card=0
    jack_numid=15  # 'Headphone Jack'

    get_device_id() {
      ${pkgs.pipewire}/bin/pw-cli ls Device 2>/dev/null \
        | ${pkgs.gawk}/bin/awk '/^[[:space:]]*id /{id=$2; gsub(/,/,"",id)} /alsa_card.pci-0000_00_1f.3/{print id; exit}'
    }

    set_input_route() {
      local dev idx
      idx="$1"
      dev=$(get_device_id)
      [ -z "$dev" ] && return
      # index 0 = analog-input-internal-mic, index 1 = analog-input-headset-mic
      ${pkgs.pipewire}/bin/pw-cli set-param "$dev" Route \
        "{ index: $idx, device: 0, props: {}, save: true }" >/dev/null 2>&1 || true
    }

    sync_from_jack() {
      if ${pkgs.alsa-utils}/bin/amixer -c "$card" cget numid="$jack_numid" 2>/dev/null \
           | ${pkgs.gnugrep}/bin/grep -q "values=on"; then
        set_input_route 1
      else
        set_input_route 0
      fi
    }

    # Initial sync at startup
    sync_from_jack

    # Watch for jack changes
    ${pkgs.alsa-utils}/bin/alsactl monitor "hw:$card" 2>/dev/null | while read -r line; do
      case "$line" in
        *"Headphone Jack"*) sync_from_jack ;;
      esac
    done
  '';
in
lib.mkIf (config.machine.profile == "laptop") {
  systemd.user.services.mic-jack-switcher = {
    description = "Switch analog input route based on headphone jack state";
    wantedBy = [ "pipewire.service" ];
    after = [
      "pipewire.service"
      "wireplumber.service"
    ];
    serviceConfig = {
      ExecStart = micJackSwitcher;
      Restart = "on-failure";
      RestartSec = 3;
    };
  };
}
