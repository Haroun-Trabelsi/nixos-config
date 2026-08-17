{ config, ... }:
let
  c = config.theme.colors;

  # Sway's output identifier is exactly "<make> <model> <serial>" — the same
  # three EDID fields Hyprland matched with `desc:`. Unlike connector names
  # (DP-1, HDMI-A-1) these are stable across driver versions, which is why the
  # desktop matched on them in the first place.
  hp = "HP Inc. HP X24ih 1CR10516K5";
in
{
  wayland.windowManager.sway.config = {
    # Sway silently ignores output blocks for displays that are not connected,
    # so ONE set of rules covers both machines with no machine.profile branch.
    # That also keeps the home-manager closure byte-identical between the base
    # and the desktop specialisation, which is what makes the specialisation
    # cheap to build and avoids .hm-backup churn on every machine swap.
    output = {
      # --- laptop ---
      "eDP-1" = {
        mode = "1920x1080@60Hz";
        position = "0 0";
        scale = "1";
        adaptive_sync = "off"; # replaces __GL_VRR_ALLOWED / __GL_GSYNC_ALLOWED
        background = "${c.mantle} solid_color";
      };

      # --- desktop ---
      # Primary, at its full 143.98 Hz.
      "${hp}" = {
        mode = "1920x1080@144Hz";
        position = "1920 0";
        scale = "1";
        background = "${c.mantle} solid_color";
      };

      # The TV, as a left-hand extension. It MUST be driven at 1080p: its
      # preferred mode is 4K@30, and 4K@30 over HDMI emits NO SIGNAL on the open
      # Blackwell driver. For real 4K use a DP->HDMI adapter.
      #
      # NOTE: the Hyprland rule matched `desc:XXX AAA`, only two EDID fields.
      # Sway needs the full "make model serial" triple, so this identifier is a
      # guess until it is read off the running desktop with:
      #   swaymsg -t get_outputs -r | jq -r '.[] | "\(.make) \(.model) \(.serial)"'
      "XXX AAA Unknown" = {
        mode = "1920x1080@60Hz";
        position = "0 0";
        scale = "1";
        background = "${c.mantle} solid_color";
      };

      # Catch-all so any other display gets a background rather than garbage.
      "*" = {
        background = "${c.mantle} solid_color";
      };
    };

    # Replaces the desktop workspace->monitor pinning. Without it sway gives
    # workspace 1 to whichever output came up first. Entries naming an absent
    # output are ignored, so this is safe on the laptop.
    workspaceOutputAssign = [
      { workspace = "1"; output = "${hp} eDP-1"; }
      { workspace = "2"; output = "${hp} eDP-1"; }
      { workspace = "3"; output = "XXX AAA Unknown eDP-1"; }
      { workspace = "4"; output = "${hp} eDP-1"; }
      { workspace = "5"; output = "${hp} eDP-1"; }
      { workspace = "6"; output = "${hp} eDP-1"; }
      { workspace = "7"; output = "${hp} eDP-1"; }
      { workspace = "8"; output = "${hp} eDP-1"; }
      { workspace = "9"; output = "${hp} eDP-1"; }
      { workspace = "10"; output = "${hp} eDP-1"; }
    ];
  };

  # `background <colour> solid_color` does still spawn one swaybg per output
  # (verified: `swaybg -o * -c #171928`), so this is not literally zero
  # processes — but swaybg draws once and then idles, against the previous
  # linux-wallpaperengine rendering at 60 fps forever, measured at ~15 W.
  #
  # Regression to be aware of: sway cannot mirror outputs, so the laptop's old
  # `,preferred,auto,1,mirror,eDP-1` rule has no equivalent — external displays
  # extend instead. Use `wl-mirror` as a client if mirroring is ever needed.
  # This is also why scripts/scripts/monitor-watcher.sh is deleted: its whole
  # job was reapplying that mirror, via a permanently running socat on the
  # Hyprland IPC socket.
}
