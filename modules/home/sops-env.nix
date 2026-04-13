{ config, lib, ... }:
let
  envDir = "${config.xdg.configHome}/environment.d";
in
{
  # Write sops secrets into ~/.config/environment.d/ so systemd exposes them
  # to all user processes (including desktop-launched apps like Claude Code).
  home.activation.sopsEnv = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    secret="/run/secrets/github_personal_access_token"
    out="${envDir}/sops-secrets.conf"

    if [ -r "$secret" ]; then
      mkdir -p "${envDir}"
      install -m 600 /dev/null "$out"
      printf 'GITHUB_PERSONAL_ACCESS_TOKEN=%s\n' "$(cat "$secret")" > "$out"
    fi
  '';
}
