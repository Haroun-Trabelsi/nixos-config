{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  src = inputs.artcraft;
  data = lib.importJSON "${src}/versions.json";
  artcraft = import "${src}/default.nix" { inherit pkgs; };

  # artcraft-nix puts each runtime dependency's default output on the RPATH,
  # but dbus keeps libdbus-1.so in its `lib` output, so every app's file
  # dialogs (rfd -> xdg-desktop-portal over libdbus) fail with "libdbus-1.so
  # not found" while the app itself starts fine. Point the RPATH at the outputs
  # that actually hold the libraries. Upstream: ipeglin/artcraft-nix#2, #4.
  fixRpath =
    pkg:
    pkg.overrideAttrs (o: {
      runtimeDependencies = map lib.getLib o.runtimeDependencies;
    });

  # A release artcraft-nix hasn't packaged yet, built with its own package.nix.
  # `hash` is the upstream SHA256SUMS.txt entry for the AppImage, in SRI form:
  #   nix hash convert --to sri --hash-algo sha256 <hex>
  # Delete an entry once `nix flake update artcraft` reaches that version.
  pinned =
    app: release: version:
    pkgs.callPackage "${src}/package.nix" {
      inherit app version release;
      info = data.apps.${app};
      inherit (data) mirrors;
      # Newer nixpkgs renamed the xorg libraries; mirrors artcraft-nix's default.nix.
      libx11 = pkgs.libx11 or pkgs.xorg.libX11;
      libxcb = pkgs.libxcb or pkgs.xorg.libxcb;
      libxcursor = pkgs.libxcursor or pkgs.xorg.libXcursor;
      libxi = pkgs.libxi or pkgs.xorg.libXi;
    };
in
{
  imports = [ inputs.artcraft.nixosModules.default ];

  # Only for its /usr/share/fonts link: the apps' text tools look there, not
  # through fontconfig. The packages themselves are installed below, with the
  # RPATH fix the module has no hook for.
  programs.artcraft = {
    enable = true;
    apps = [ ];
  };

  environment.systemPackages = map fixRpath [
    artcraft.photocraft
    artcraft.effectcraft

    # artcraft-nix stops at filmcraft 0.4.0: 0.5+ also dlopen() libva (VA-API)
    # and libcuda / libnvcuvid / libnvidia-encode (NVDEC/NVENC), which its
    # package doesn't provide, so its updater rejects them. Without them video
    # decode/encode silently falls back to software. The NVIDIA libs only exist
    # in the driver dir, so that goes on the RPATH as a runtime path.
    ((pinned "filmcraft" {
      tag = "v0.7.2";
      file = "filmcraft-0.7.2-linux-x86_64.AppImage";
      bin = "filmcraft";
      hash = "sha256-q/kg2Y0BWGDh9brcbPBQfY+BFvXDKPf38kJfBoqzrug=";
    } "0.7.2").overrideAttrs (o: {
      runtimeDependencies = o.runtimeDependencies ++ [ pkgs.libva ];
      appendRunpaths = [ "/run/opengl-driver/lib" ];
    }))
  ];
}
