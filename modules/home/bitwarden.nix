{ pkgs, ... }:
{
  # The desktop app, replacing the noctalia bitwarden plugin.
  #
  # The plugin drove `bw serve` through the CLI and could only ever search and
  # copy — and it still needed the master password typed into its unlock panel,
  # because the API key in sops authenticates but cannot decrypt. Given the
  # unlock was unavoidable either way, the real client is worth more: it edits,
  # syncs, handles attachments and TOTP, and owns its own session lifetime.
  home.packages = with pkgs; [ bitwarden-desktop ];
}
