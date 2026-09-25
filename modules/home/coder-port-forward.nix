{
  pkgs,
  lib,
  config,
  ...
}:
let
  # Coder workspace whose dev servers get forwarded.
  workspace = "haroun";

  # The workspace's dev-server ladder: backend 8000 upwards, frontend 5173
  # upwards, each extra copy taking the next port. Forwarded to the same port
  # locally, so http://localhost:5173 in the local browser is the workspace's
  # frontend.
  #
  # Ten rungs each, well past the four copies that actually run, so a stray
  # server holding a port and pushing the rest up doesn't fall off the end.
  rungs = 10;
  ports = lib.range 8000 (8000 + rungs - 1) ++ lib.range 5173 (5173 + rungs - 1);

  # Bound to 127.0.0.1, not all interfaces: these are someone's dev servers,
  # and a tunnel that is always up shouldn't publish them to the LAN.
  forwards = lib.concatMapStringsSep " " (
    p: "-L 127.0.0.1:${toString p}:localhost:${toString p}"
  ) ports;

  # -F none for the same reason as claude-notify-bridge.nix: a unit that
  # silently depends on the current state of ~/.ssh/config breaks the next time
  # something rewrites that file.
  #
  # No ExitOnForwardFailure, unlike the bridge tunnels. Those carry a single
  # forward that is the whole point of the unit; here a local process already
  # holding one of the ports should only cost that one port (ssh logs a
  # warning), not take the rest down in a restart loop.
  tunnel = pkgs.writeShellScript "coder-port-forward" ''
    exec ${lib.getExe' pkgs.openssh "ssh"} -N \
      -F none \
      -o ProxyCommand="${lib.getExe' pkgs.coder "coder"} --global-config ${config.xdg.configHome}/coderv2 ssh --stdio --ssh-host-prefix coder. %h" \
      -o BatchMode=yes \
      -o StrictHostKeyChecking=no \
      -o UserKnownHostsFile=/dev/null \
      -o LogLevel=ERROR \
      -o ControlMaster=no \
      -o ControlPath=none \
      -o ServerAliveInterval=30 \
      -o ServerAliveCountMax=3 \
      ${forwards} \
      coder.${workspace}
  '';
in
{
  # A standalone unit rather than LocalForward in ssh_config: the terminal
  # session is `coder ssh haroun` (herdr's binding), which never reads
  # ssh_config, and this way the ports don't depend on which client happens to
  # be connected.
  systemd.user.services.coder-port-forward = {
    Unit = {
      Description = "Forward the Coder workspace's dev-server ports to localhost";
      After = [
        "graphical-session.target"
        "network-online.target"
      ];
      PartOf = [ "graphical-session.target" ];
      # Retry forever: the default start limit gives up after five tries in
      # ten seconds, which a stopped workspace would trip immediately.
      StartLimitIntervalSec = 0;
    };

    Service = {
      ExecStart = "${tunnel}";
      Restart = "always";
      RestartSec = 15;
      NoNewPrivileges = true;
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };
}
