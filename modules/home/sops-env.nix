{ config, lib, ... }:
let
  envDir = "${config.xdg.configHome}/environment.d";

  # sops secret name -> environment variable name.
  #
  # Each is written only if /run/secrets/<name> actually exists, so adding a row
  # here before the secret is in secrets/secrets.yaml is harmless — it simply
  # does nothing until `sops secrets/secrets.yaml` grows the key.
  exports = {
    github_personal_access_token = "GITHUB_PERSONAL_ACCESS_TOKEN";
  };

  writeOne = name: var: ''
    secret="/run/secrets/${name}"
    if [ -r "$secret" ]; then
      printf '${var}=%s\n' "$(cat "$secret")" >> "$out"
    fi
  '';
in
{
  # Write sops secrets into ~/.config/environment.d/ so systemd exposes them to
  # all user processes — including desktop-launched apps and noctalia plugins,
  # which never source a shell rc.
  #
  # NOTE: systemd reads environment.d when the user manager starts, so a new
  # value needs a logout/login (or `systemctl --user daemon-reexec` plus a
  # restart of whatever needs it) before anything sees it.
  home.activation.sopsEnv = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    out="${envDir}/sops-secrets.conf"
    mkdir -p "${envDir}"
    # Truncate first: a secret removed from the map should disappear from the
    # file rather than linger from a previous generation.
    install -m 600 /dev/null "$out"
    ${lib.concatStrings (lib.mapAttrsToList writeOne exports)}
  '';
}
