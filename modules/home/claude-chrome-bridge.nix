{
  pkgs,
  lib,
  config,
  ...
}:
let
  # TCP port the workspace-side claude-in-chrome MCP tooling expects to reach.
  # Also hardcoded on the Coder workspace side; change it here and there together.
  port = 9229;

  # Coder workspace to tunnel back from.
  workspace = "haroun";

  # Bridges TCP connections (arriving over the reverse SSH tunnel) to the
  # Chrome Native Messaging Host's local unix socket, so claude-in-chrome
  # running inside the Coder workspace can drive the real Chrome instance on
  # this machine.
  #
  # Bound to 127.0.0.1, not the script's own 0.0.0.0 default: the only
  # legitimate path in is the ssh tunnel, and a service that runs forever
  # shouldn't default to a listener reachable from the LAN.
  bridgeHost = pkgs.writeTextFile {
    name = "claude-chrome-bridge-host";
    executable = true;
    text = ''
      #!${lib.getExe' pkgs.nodejs_24 "node"}
      "use strict";

      const net = require("net");
      const fs = require("fs");
      const path = require("path");
      const os = require("os");

      const SOCK_DIR = `/tmp/claude-mcp-browser-bridge-''${process.env.BRIDGE_USER || os.userInfo().username}`;
      const TCP_PORT = parseInt(process.env.BRIDGE_PORT || "${toString port}", 10);
      const TCP_HOST = process.env.BRIDGE_HOST || "127.0.0.1";

      function log(msg) {
        console.error(`[bridge-host] ''${msg}`);
      }

      function findSock() {
        try {
          const files = fs.readdirSync(SOCK_DIR).filter((f) => f.endsWith(".sock"));
          if (files.length === 0) return null;
          files.sort();
          return path.join(SOCK_DIR, files[files.length - 1]);
        } catch {
          return null;
        }
      }

      const server = net.createServer((tcpConn) => {
        const addr = `''${tcpConn.remoteAddress}:''${tcpConn.remotePort}`;
        const sockPath = findSock();

        if (!sockPath) {
          log(`TCP client ''${addr} connected but no NMH socket in ''${SOCK_DIR}`);
          tcpConn.destroy();
          return;
        }

        log(`TCP client ''${addr} -> NMH ''${sockPath}`);

        const nmh = net.createConnection(sockPath, () => {
          log(`Connected to NMH socket`);
        });

        tcpConn.pipe(nmh);
        nmh.pipe(tcpConn);

        tcpConn.on("error", (e) => {
          log(`TCP error: ''${e.message}`);
          nmh.destroy();
        });
        nmh.on("error", (e) => {
          log(`NMH error: ''${e.message}`);
          tcpConn.destroy();
        });
        tcpConn.on("close", () => {
          log(`TCP client ''${addr} disconnected`);
          nmh.destroy();
        });
        nmh.on("close", () => {
          log(`NMH disconnected`);
          tcpConn.destroy();
        });
      });

      server.listen(TCP_PORT, TCP_HOST, () => {
        log(`Listening on ''${TCP_HOST}:''${TCP_PORT}`);
        log(`NMH socket dir: ''${SOCK_DIR}`);
        const sock = findSock();
        if (sock) log(`Found NMH socket: ''${sock}`);
        else log(`No NMH socket yet, will check on each connection`);
      });
    '';
  };

  # ssh reads its own config for none of this on purpose: -F none, same
  # reasoning as claude-notify-bridge.nix. A systemd unit that silently
  # depends on the current state of ~/.ssh/config breaks the next time
  # something rewrites that file.
  tunnel = pkgs.writeShellScript "claude-chrome-bridge-tunnel" ''
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
      -o ExitOnForwardFailure=yes \
      -R ${toString port}:127.0.0.1:${toString port} \
      coder.${workspace}
  '';
in
{
  systemd.user.services.claude-chrome-bridge = {
    Unit = {
      Description = "TCP-to-NMH-socket bridge for claude-in-chrome running in a Coder workspace";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${bridgeHost}";
      Restart = "on-failure";
      RestartSec = 5;
      NoNewPrivileges = true;
      PrivateTmp = false; # must see the real /tmp to find the NMH socket
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };

  # The tunnel is its own unit rather than a RemoteForward in ssh_config, for
  # the same reason as claude-notify-tunnel: it needs to survive independently
  # of whatever client (VS Code, a terminal) happens to be connected, and stay
  # up while nothing is.
  systemd.user.services.claude-chrome-bridge-tunnel = {
    Unit = {
      Description = "Reverse SSH tunnel carrying claude-in-chrome traffic back from the Coder workspace";
      Requires = [ "claude-chrome-bridge.service" ];
      After = [
        "claude-chrome-bridge.service"
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
