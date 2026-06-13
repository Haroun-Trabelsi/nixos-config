{ ... }:
{
  # game streaming host for Moonlight clients
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true; # required for KMS screen capture on Wayland
    openFirewall = true;
  };
}
