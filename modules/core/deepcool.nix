{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    deepcool-digital-linux
    openrgb
  ];

  systemd.services.deepcool-digital = {
    description = "DeepCool Digital cooler display";
    wantedBy = [ "multi-user.target" ];
    after = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.deepcool-digital-linux}/bin/deepcool-digital-linux";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  services.hardware.openrgb = {
    enable = true;
    motherboard = "amd";
  };
}
