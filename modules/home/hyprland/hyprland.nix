{ pkgs, inputs, ... }:
{
  home.packages = with pkgs; [
    grimblast
    hyprpicker
    grim
    slurp
    wl-clip-persist
    cliphist
    wf-recorder
    glib
    wayland
    direnv
    tesseract
  ];

  systemd.user.targets.hyprland-session.Unit.Wants = [ "xdg-desktop-autostart.target" ];

  wayland.windowManager.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.x86_64-linux.hyprland;
    portalPackage = inputs.hyprland.packages.x86_64-linux.xdg-desktop-portal-hyprland;
    xwayland.enable = true;
    systemd.enable = true;
  };
}
