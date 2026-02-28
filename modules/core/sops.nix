{ inputs, username, lib, ... }:
let
  secretsPath = ../../secrets/secrets.yaml;
  hasSecrets = builtins.pathExists secretsPath;
in
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  config = lib.mkIf hasSecrets {
    sops = {
      defaultSopsFile = secretsPath;
      age.keyFile = "/home/${username}/.config/sops/age/keys.txt";

      secrets = {
        "ssh_id_github" = {
          owner = username;
          mode = "0600";
          path = "/home/${username}/.ssh/id_github";
        };
        "ssh_id_github_work" = {
          owner = username;
          mode = "0600";
          path = "/home/${username}/.ssh/id_github_work";
        };
      };
    };
  };
}
