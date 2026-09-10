{ pkgs, ... }:
# Compositor-agnostic Wayland tooling, shared by BOTH machines.
#
# These used to be duplicated in sway/sway.nix and hyprland/hyprland.nix, both of
# which set `home.packages` OUTSIDE their `enable` gate — so the gate only ever
# covered `wayland.windowManager.*` and every tool landed on both machines
# anyway. grim, slurp, cliphist, wf-recorder, hyprpicker and tesseract were
# installed twice over, and the laptop carried grimblast while the tower carried
# grimshot and wlsunset, and nwg-displays was added twice.
#
# Anything genuinely tied to one compositor stays in that compositor's module,
# inside a `lib.mkIf`. Anything that speaks plain wlroots/Wayland protocols
# belongs here.
{
  home.packages = with pkgs; [
    grim # screenshot backend for both grimshot and grimblast
    slurp # region select
    wl-clipboard # wl-copy / wl-paste
    wl-clip-persist # keeps clipboard contents after the source window closes
    cliphist # clipboard history, driven by scripts/scripts/clipboard-picker.sh
    wf-recorder # screen recording, scripts/scripts/screenrecord.sh
    hyprpicker # colour picker — compositor-agnostic despite the name
    tesseract # OCR, scripts/scripts/ocr.sh
    nwg-displays # GUI output layout; speaks both sway and hyprland
  ];
}
