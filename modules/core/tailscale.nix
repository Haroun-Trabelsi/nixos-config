{ config, ... }:
{
  # Shared across both machines: the whole point of a mesh VPN is reaching the
  # same nodes regardless of which computer this SSD is plugged into. Node
  # identity lives in /var/lib/tailscale on the shared root, so the disk keeps
  # ONE Tailscale identity ("desktop") rather than re-authenticating per machine.
  services.tailscale = {
    enable = true;

    # Opens UDP 41641 so peers can reach this node directly. Without it,
    # traffic still works but falls back to a DERP relay — higher latency and,
    # relevant here, more radio wakeups on battery.
    openFirewall = true;

    # "client" sets up the routing needed to USE subnet routes and exit nodes.
    # Change to "both" only if this machine should advertise routes itself,
    # which also needs IP forwarding and is not wanted on a laptop.
    useRoutingFeatures = "client";

    # Joining the tailnet used to be a documented manual step (`sudo tailscale
    # up`), i.e. a fresh install came up with no tailnet and no record of how to
    # fix that beyond a README line. With an auth key on disk, tailscaled joins
    # on first boot with no interaction.
    #
    # The node's IDENTITY still lives in /var/lib/tailscale and is genuinely not
    # reproducible — a reinstall is a NEW node, and the old one lingers in the
    # admin console until you remove it. That is how the protocol works; what is
    # fixed here is that joining no longer needs a human.
    #
    # Generate a key at https://login.tailscale.com/admin/settings/keys — make it
    # REUSABLE and set an expiry you are happy with (90 days max), then put it in
    # secrets/secrets.yaml under `tailscale_auth_key`:
    #   sops secrets/secrets.yaml
    #
    # Until that key exists the option below points at a secret sops will not
    # create, so it is guarded on the secret being declared.
    authKeyFile = config.sops.secrets."tailscale_auth_key".path or null;
  };

  # Trust the tailnet interface: this is a private authenticated network, and
  # without it the firewall above would block SSH from other nodes — which is
  # precisely the point of installing this (running mongo/redis/docker on a
  # remote box and reaching it over SSH instead of locally).
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  # tailscaled sends periodic keepalives, so it is not free on battery — but it
  # is a small Go daemon and the cost is well under the browser's. If it ever
  # matters, `tailscale down` stops the traffic without disabling the service.
}
