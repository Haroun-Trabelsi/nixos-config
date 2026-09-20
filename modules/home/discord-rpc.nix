{ pkgs, ... }:
let
  # Static Discord Rich Presence, independent of any single app -- the
  # vscord VSCodium extension only ever showed "editing X", this shows a
  # fixed status for as long as Vesktop is open, whatever you're actually
  # doing on the machine.
  #
  # Vesktop's bundled arRPC speaks the same local IPC protocol the real
  # Discord desktop client exposes (checked in the shipped arRpcWorker.js:
  # it listens on $XDG_RUNTIME_DIR/discord-ipc-0, the exact path pypresence
  # looks for), so this connects to Vesktop, not to Discord's own client --
  # there's no need for one to also be running.
  clientId = "1525508104886812822";
  status = "Coding On NixOS";

  presenceScript = pkgs.writeTextFile {
    name = "discord-rich-presence";
    executable = true;
    text = ''
      #!${pkgs.python3.withPackages (ps: [ ps.pypresence ])}/bin/python3
      """Keeps a static Rich Presence up for as long as Vesktop is running.

      Vesktop isn't autostarted (see hyprland/exec-once.nix), so the IPC
      socket this connects to may not exist yet, or may disappear if Vesktop
      is closed -- retry forever rather than exit.
      """
      import time
      from pypresence import Presence

      CLIENT_ID = "${clientId}"
      RETRY_SECONDS = 15
      UPDATE_SECONDS = 15  # also doubles as the disconnect detector

      def main():
          while True:
              rpc = Presence(CLIENT_ID)
              try:
                  rpc.connect()
                  start = int(time.time())
                  while True:
                      rpc.update(details="${status}", start=start)
                      time.sleep(UPDATE_SECONDS)
              except Exception:
                  time.sleep(RETRY_SECONDS)

      if __name__ == "__main__":
          main()
    '';
  };
in
{
  systemd.user.services.discord-rich-presence = {
    Unit = {
      Description = "Static Discord Rich Presence (\"${status}\"), shown whenever Vesktop is running";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${presenceScript}";
      Restart = "on-failure";
      RestartSec = 15;
      NoNewPrivileges = true;
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };
}
