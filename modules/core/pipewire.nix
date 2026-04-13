{ pkgs, ... }:
let
  audioPortSwitcher = pkgs.writeShellScript "audio-port-switcher" ''
    # Switch the Built-in Audio ALSA device port when the default sink changes.
    # Uses pw-cli because wpctl set-route can't handle overlapping route indices
    # between HDMI and analog outputs on the same HDA Intel PCH card.
    # Route index 3 + device 4 = analog-output-lineout
    # Route index 4 + device 4 = analog-output-headphones

    get_device_id() {
      ${pkgs.pipewire}/bin/pw-cli ls Device 2>/dev/null \
        | ${pkgs.gawk}/bin/awk '/^[[:space:]]*id /{id=$2; gsub(/,/,"",id)} /alsa_card.pci-0000_00_1f.3/{print id; exit}'
    }

    switch_port() {
      local dev
      dev=$(get_device_id)
      [ -z "$dev" ] && return
      case "$1" in
        speakers)   ${pkgs.pipewire}/bin/pw-cli set-param "$dev" Route '{ index: 3, device: 4, props: {}, save: true }' ;;
        headphones) ${pkgs.pipewire}/bin/pw-cli set-param "$dev" Route '{ index: 4, device: 4, props: {}, save: true }' ;;
      esac
    }

    # Monitor default-sink metadata changes
    ${pkgs.pipewire}/bin/pw-metadata -n default -m 2>/dev/null | while IFS= read -r line; do
      if echo "$line" | ${pkgs.gnugrep}/bin/grep -q "default.audio.sink"; then
        name=$(echo "$line" | ${pkgs.gnused}/bin/sed -n 's/.*"name":"\([^"]*\)".*/\1/p')
        switch_port "$name"
      fi
    done
  '';
in
{
  services = {
    pipewire = {
      enable = true;
      pulse.enable = true;
      wireplumber.enable = true;

      alsa = {
        enable = true;
        support32Bit = true;
      };

      extraConfig.pipewire-pulse."90-disable-cork" = {
        "pulse.cmd" = [
          {
            cmd = "unload-module";
            args = "module-role-cork";
          }
        ];
      };

      extraConfig.pipewire."92-virtual-sinks" = {
        "context.modules" = [
          {
            name = "libpipewire-module-loopback";
            args = {
              "node.description" = "Speakers (Line Out)";
              "capture.props" = {
                "node.name" = "speakers";
                "media.class" = "Audio/Sink";
                "audio.position" = "FL,FR";
              };
              "playback.props" = {
                "node.name" = "speakers-loopback";
                "target.object" = "alsa_output.pci-0000_00_1f.3.analog-stereo";
                "stream.dont-remix" = true;
                "node.passive" = true;
              };
            };
          }
          {
            name = "libpipewire-module-loopback";
            args = {
              "node.description" = "Headphones";
              "capture.props" = {
                "node.name" = "headphones";
                "media.class" = "Audio/Sink";
                "audio.position" = "FL,FR";
              };
              "playback.props" = {
                "node.name" = "headphones-loopback";
                "target.object" = "alsa_output.pci-0000_00_1f.3.analog-stereo";
                "stream.dont-remix" = true;
                "node.passive" = true;
              };
            };
          }
        ];
      };

      wireplumber.extraConfig."49-default-volume" = {
        "wireplumber.settings" = {
          "device.routes.default-sink-volume" = 1.0;
        };
      };

      wireplumber.extraConfig."50-deprioritize-raw-sink" = {
        "monitor.alsa.rules" = [
          {
            matches = [
              { "node.name" = "alsa_output.pci-0000_00_1f.3.analog-stereo"; }
            ];
            actions = {
              update-props = {
                "node.description" = "Built-in Audio (Raw)";
                "priority.session" = 0;
                "priority.driver" = 0;
              };
            };
          }
        ];
      };
    };
  };

  # Daemon that switches the physical ALSA port when the default sink changes
  systemd.user.services.audio-port-switcher = {
    description = "Switch ALSA output port based on default PipeWire sink";
    wantedBy = [ "pipewire.service" ];
    after = [ "pipewire.service" "wireplumber.service" ];
    serviceConfig = {
      ExecStart = audioPortSwitcher;
      Restart = "on-failure";
      RestartSec = 3;
    };
  };

  hardware.alsa.enablePersistence = true;
  environment.systemPackages = with pkgs; [ alsa-utils ];
}
