{ pkgs, ... }:
{
  home.packages = with pkgs; [ swayosd ];

  # The keybindings that used to live here moved into modules/home/sway/binds.nix
  # (sway expresses the bindl/binde/bindr variants as --locked / plain / --release),
  # and swayosd-server is started from modules/home/sway/startup.nix.
  #
  # swayosd-libinput-backend needs the system-level service for caps-lock, and
  # brightness control needs services.udev.packages = [ brightnessctl ] because
  # /sys/class/backlight is root-owned and this user is not in `video`.

  xdg.configFile."swayosd/config.toml".text = ''
    [server]
    max_volume = 100
    show_percentage = true
  '';

  xdg.configFile."swayosd/style.css".text = ''
    window {
        padding: 0px 10px;
        border-radius: 25px;
        border: 10px;
        background: alpha(#212337, 0.99);
    }

    #container {
        margin: 15px;
    }

    image, label {
        color: #ebfafa;
    }

    progressbar:disabled,
    image:disabled {
        opacity: 0.95;
    }

    progressbar {
        min-height: 6px;
        border-radius: 999px;
        background: transparent;
        border: none;
    }
    trough {
        min-height: inherit;
        border-radius: inherit;
        border: none;
        background: alpha(#7081d0, 0.2);
    }
    progress {
        min-height: inherit;
        border-radius: inherit;
        border: none;
        background: #a48cf2;
    }
  '';
}
