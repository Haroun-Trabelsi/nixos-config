{ ... }:
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
  };

  # Trust the tailnet interface: this is a private authenticated network, and
  # without it the firewall above would block SSH from other nodes — which is
  # precisely the point of installing this (running mongo/redis/docker on a
  # remote box and reaching it over SSH instead of locally).
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  # tailscaled sends periodic keepalives, so it is not free on battery — but it
  # is a small Go daemon and the cost is well under the browser's. If it ever
  # matters, `tailscale down` stops the traffic without disabling the service.
  #
  # First run needs an interactive login, which cannot be done from a config:
  #   sudo tailscale up
}
