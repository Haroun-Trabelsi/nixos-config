{ pkgs, config, osConfig, ... }:
{
  # Replaces Electron Spotify + spicetify.
  #
  # Every librespot-based client (spotify-player, ncspot, psst) requires Spotify
  # PREMIUM to stream — the free tier cannot play through the API at all. So the
  # default here is free and offline: mpd serving local files, driven by rmpc
  # (Rust TUI, ~30 MB RSS, effectively zero idle CPU) instead of an Electron app
  # that idles at 1-3 W.
  #
  # For on-demand streaming, use the Spotify web player as a tab in the browser
  # that is already open — free tier works there, and a tab costs far less than
  # a second Electron runtime.
  #
  # IF YOU EVER HAVE PREMIUM: add pkgs.spotify-player below and point the
  # $mod+S bind at it. That is the whole change.
  services.mpd = {
    # laptop: mpd + rmpc. The desktop uses Spotify + spicetify
    enable = osConfig.machine.profile == "laptop";
    musicDirectory = "${config.home.homeDirectory}/Music";

    # Socket activation: mpd is not running at all until a client connects, so
    # it costs nothing on a machine that is not playing music.
    network.startWhenNeeded = true;

    extraConfig = ''
      audio_output {
        type    "pipewire"
        name    "PipeWire"
      }

      # No resampling in mpd — pipewire's allowed-rates list already avoids it
      # for 44.1k/48k material (see modules/core/pipewire.nix).
      audio_output_format "44100:16:2"
      restore_paused      "yes"
      auto_update         "yes"
    '';
  };

  home.packages = with pkgs; [
    rmpc # TUI client, bound to $mod+S
    mpc # scripting/CLI, used by the media-key binds
    # yt-dlp is already installed (packages/cli.nix) — use it to populate ~/Music
  ];

  # Note: mpd does not speak MPRIS, so playerctl and the XF86Audio* binds do not
  # control it (they still control browser audio, which is the common case).
  # If you want the media keys to drive mpd too, add pkgs.mpdris2 and start it
  # from sway's startup list — one more small daemon, deliberately not added by
  # default.
}
