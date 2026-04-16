{ ... }:
{
  security = {
    rtkit.enable = true;
    sudo.enable = true;

    # qylock uses PamContext with the default "login" service,
    # which NixOS ships with out of the box — no extra entry needed.
  };
}
