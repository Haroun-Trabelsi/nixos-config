{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  src = inputs.artcraft;
  data = lib.importJSON "${src}/versions.json";

  # A release artcraft-nix hasn't packaged yet, built with its own package.nix.
  # `hash` is the upstream SHA256SUMS.txt entry for the AppImage, in SRI form:
  #   nix hash convert --to sri --hash-algo sha256 <hex>
  # Delete an entry once `nix flake update artcraft` reaches that version.
  pinned = app: release: version:
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

  # Also links /usr/share/fonts to the system fonts: the apps' text tools only
  # look there, not through fontconfig.
  programs.artcraft = {
    enable = true;
    apps = [
      "photocraft"
      "effectcraft"
    ];
  };

  # artcraft-nix stops at filmcraft 0.4.0 (its updater has skipped 0.5–0.7).
  # Newer filmcraft also dlopen()s libva (VA-API) and libnvidia-encode (NVENC),
  # which artcraft-nix's package doesn't put on the RPATH; without them video
  # encode/decode silently falls back to software. The NVIDIA lib only exists
  # in the driver dir, so that goes on the RPATH as a runtime path.
  environment.systemPackages = [
    ((pinned "filmcraft" {
      tag = "v0.7.2";
      file = "filmcraft-0.7.2-linux-x86_64.AppImage";
      bin = "filmcraft";
      hash = "sha256-q/kg2Y0BWGDh9brcbPBQfY+BFvXDKPf38kJfBoqzrug=";
    } "0.7.2").overrideAttrs (o: {
      runtimeDependencies = o.runtimeDependencies ++ [ (lib.getLib pkgs.libva) ];
      appendRunpaths = [ "/run/opengl-driver/lib" ];
    }))
  ];
}
