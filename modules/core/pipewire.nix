{ pkgs, ... }:
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
    };
  };

  hardware.alsa.enablePersistence = true;
  environment.systemPackages = with pkgs; [ alsa-utils ];
}
