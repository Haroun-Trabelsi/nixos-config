{ config, ... }:
let
  c = config.theme.colors;
in
{
  # mako: a small C layer-shell daemon with essentially zero idle wakeups.
  # Replaces noctalia's notification centre; `makoctl restore` on Super+W
  # replaces its history toggle.
  #
  # (The old config also exec'd `swaync` at login, which was never installed by
  # this flake at all — a dead line for as long as it existed.)
  services.mako = {
    enable = true;
    settings = {
      font = "JetBrainsMono Nerd Font 11";
      background-color = c.mantle;
      text-color = c.text;
      border-color = c.tertiary;
      progress-color = "over ${c.primary}";
      border-size = 2;
      border-radius = 8;
      padding = "12";
      margin = "10";
      default-timeout = 6000;
      max-visible = 5;
      anchor = "top-right";
      layer = "overlay";

      "urgency=critical" = {
        border-color = c.error;
        default-timeout = 0;
      };
    };
  };
}
