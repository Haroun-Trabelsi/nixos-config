{
  pkgs,
  lib,
  config,
  ...
}:
let
  # Loopback port. Also hardcoded in the workspace's ~/.claude/settings.json
  # notification hook; change it here and you must change it there too.
  port = 8765;

  # Coder workspace to tunnel back from.
  workspace = "haroun";

  listener = pkgs.writeTextFile {
    name = "claude-notify-listener";
    executable = true;
    text = ''
      #!${pkgs.python3}/bin/python3
      """Local half of the Claude Code notification bridge.

      Claude Code runs inside a remote Coder workspace, so its hooks execute in
      a container with no route to this machine's Wayland/D-Bus session --
      notify-send there notifies nobody. The hook instead POSTs to loopback in
      the container, ssh's RemoteForward carries that back here, and this
      process turns it into a real desktop notification.

      Bound to 127.0.0.1 deliberately: the only way in is the ssh tunnel.
      """
      import http.server
      import subprocess

      PORT = ${toString port}
      MAX_BODY = 4096  # a notification line, not a payload
      MAX_CHARS = 200

      def clean(raw):
          """Notification text arrives from another machine -- treat it as data."""
          text = "".join(c for c in raw if c.isprintable() or c == " ").strip()
          if len(text) > MAX_CHARS:
              text = text[: MAX_CHARS - 1] + "…"
          return text

      class Handler(http.server.BaseHTTPRequestHandler):
          protocol_version = "HTTP/1.1"

          def do_POST(self):
              try:
                  length = min(int(self.headers.get("Content-Length") or 0), MAX_BODY)
              except ValueError:
                  length = 0
              raw = self.rfile.read(length).decode("utf-8", "replace") if length else ""
              message = clean(raw) or "Claude Code needs your attention"
              # argv, never a shell, and "--" so a message starting with "-" is
              # not read as a notify-send flag.
              subprocess.run(
                  [
                      "notify-send",
                      "--app-name=Claude Code",
                      "--urgency=normal",
                      "--",
                      "Claude Code",
                      message,
                  ],
                  check=False,
              )
              self.send_response(204)
              self.end_headers()

          def do_GET(self):
              # Health check, so the tunnel can be tested without popping a toast.
              body = b"claude-notify-listener ok\n"
              self.send_response(200)
              self.send_header("Content-Type", "text/plain")
              self.send_header("Content-Length", str(len(body)))
              self.end_headers()
              self.wfile.write(body)

          def log_message(self, *_args):
              pass

      if __name__ == "__main__":
          http.server.ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
    '';
  };
  # ssh reads its own config for none of this on purpose: -F none. A systemd
  # unit that silently depends on the current state of ~/.ssh/config is a unit
  # that breaks the next time something rewrites that file -- and here two
  # things do (home-manager's activation copy, and the Coder extension moving
  # its Include block back to the top on every connect).
  tunnel = pkgs.writeShellScript "claude-notify-tunnel" ''
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
  systemd.user.services.claude-notify-bridge = {
    Unit = {
      Description = "Desktop notifications for Claude Code running in a Coder workspace";
      # notify-send needs the session bus, so this must not outlive the session.
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${listener}";
      Restart = "on-failure";
      RestartSec = 5;
      # The script calls notify-send by name; a user unit's PATH is otherwise
      # bash and nothing else (the same trap lock.nix documents for swayidle).
      Environment = [ "PATH=${lib.makeBinPath [ pkgs.libnotify ]}" ];
      NoNewPrivileges = true;
      PrivateTmp = true;
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };

  # The tunnel is its own unit rather than a RemoteForward in ssh_config,
  # because nothing in the VS Code path ever reads ssh_config.
  # jeanp413.open-remote-ssh speaks SSH from JavaScript (the ssh2 library) and
  # the Coder extension proxies it through `coder ssh --stdio` -- there is no
  # openssh client process in that chain at all. `ssh -G` resolving a
  # RemoteForward proves only that openssh WOULD honour it; the extension
  # parses a subset of ssh_config itself and RemoteForward is not in it.
  #
  # A standalone tunnel is better anyway: it survives VS Code reconnecting and
  # stays up while the editor is closed.
  systemd.user.services.claude-notify-tunnel = {
    Unit = {
      Description = "Reverse SSH tunnel carrying Claude Code notifications back from the Coder workspace";
      # Pointless without something listening on the near end.
      Requires = [ "claude-notify-bridge.service" ];
      After = [
        "claude-notify-bridge.service"
        "network-online.target"
      ];
      PartOf = [ "graphical-session.target" ];
      # Retry forever: the default start limit gives up after five tries in ten
      # seconds, which a stopped workspace would trip immediately.
      StartLimitIntervalSec = 0;
    };

    Service = {
      ExecStart = "${tunnel}";
      # The workspace is often stopped and the laptop is often off the network;
      # a dropped tunnel must come back on its own.
      Restart = "always";
      RestartSec = 15;
      NoNewPrivileges = true;
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };
}
