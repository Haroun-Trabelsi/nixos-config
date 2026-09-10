{
  inputs,
  username,
  lib,
  ...
}:
let
  secretsPath = ../../secrets/secrets.yaml;
  hasSecrets = builtins.pathExists secretsPath;

  # sops encrypts VALUES, not keys, so the key names are readable in the
  # committed file. That lets us declare only the secrets that actually exist:
  # sops-nix fails activation for a declared secret that is missing from the
  # file, so a hardcoded list turns "I have not added that key yet" into "my
  # system will not rebuild".
  presentKeys =
    if hasSecrets then
      let
        content = builtins.readFile secretsPath;
        lines = lib.splitString "\n" content;
        keyOf =
          l:
          let
            m = builtins.match "^([a-zA-Z0-9_]+):.*" l;
          in
          if m == null then null else builtins.head m;
      in
      builtins.filter (k: k != null && k != "sops") (map keyOf lines)
    else
      [ ];

  has = k: builtins.elem k presentKeys;

  # Every secret this config knows how to consume. Anything here that is not yet
  # in secrets.yaml is simply not declared, and the feature depending on it stays
  # off rather than breaking the build.
  wanted = {
    ssh_id_github = {
      owner = username;
      mode = "0600";
      path = "/home/${username}/.ssh/id_github";
    };
    github_personal_access_token = {
      owner = username;
      mode = "0400";
    };
    # Consumed by services.tailscale.authKeyFile (modules/core/tailscale.nix) so
    # a fresh install joins the tailnet with no interactive `tailscale up`.
    # Owned by root: tailscaled reads it before any user session exists.
    tailscale_auth_key = {
      mode = "0400";
    };
  };
in
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  config = lib.mkIf hasSecrets {
    sops = {
      defaultSopsFile = secretsPath;

      # The age identity that decrypts everything above.
      #
      # NOTE ON RECOVERY: .sops.yaml should list MORE THAN ONE recipient. With a
      # single one, losing ~/.config/sops/age/keys.txt loses every secret here —
      # and secrets/bitwarden_backup.age is encrypted to that same key, so the
      # backup you would reach for is locked behind the thing you lost. Adding a
      # second recipient whose private half lives OFF this disk fixes that, and
      # needs no change in this file: any listed recipient can decrypt.
      #
      # `age.sshKeyPaths` is NOT used, and cannot be here: it needs an SSH host
      # key, and services.openssh is not enabled on either machine, so
      # /etc/ssh/ssh_host_*_key does not exist.
      age.keyFile = "/home/${username}/.config/sops/age/keys.txt";

      secrets = lib.filterAttrs (name: _: has name) wanted;
    };
  };
}
