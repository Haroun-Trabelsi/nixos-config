{
  lib,
  stdenvNoCC,
  fetchurl,
  ...
}:
# The Coder CLI, pinned.
#
# This was installed imperatively by coder.com's install script into
# /usr/local/bin/coder — a 421 MB static Go binary that nix knew nothing about.
# modules/home/packages/dev.nix appended /usr/local/bin to PATH just to reach it,
# with a comment admitting the trade: "it is not reproducible (a fresh install of
# this flake will not have the binary), and it is never garbage-collected or
# rebuilt when nixpkgs moves".
#
# nixpkgs DOES package coder, but at 2.28.6 against the 2.36.0 deployment this
# talks to. Coder is version-sensitive between CLI and deployment, so the version
# has to be chosen here rather than inherited from nixpkgs.
#
# It is the upstream RELEASE BINARY rather than a source build: coder builds its
# own frontend, which is a heavy JS toolchain, and the point here is to pin the
# exact artifact the deployment expects. The binary is statically linked
# (CGO_ENABLED=0), so it needs no patchelf.
#
# The hash comes from upstream's published checksums file, not from downloading
# the tarball:
#   curl -sL https://github.com/coder/coder/releases/download/v$VERSION/coder_${VERSION}_checksums.txt
# Convert the hex to SRI with:
#   nix hash convert --hash-algo sha256 --to sri <hex>
let
  version = "2.36.0";
in
stdenvNoCC.mkDerivation {
  pname = "coder";
  inherit version;

  src = fetchurl {
    url = "https://github.com/coder/coder/releases/download/v${version}/coder_${version}_linux_amd64.tar.gz";
    hash = "sha256-x9cFP8D/n5kgOmXua8AxLFESqIQomlomUiai3PDtVy4=";
  };

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    install -Dm755 coder "$out/bin/coder"
    runHook postInstall
  '';

  meta = {
    description = "Coder CLI, pinned to the version this deployment runs";
    homepage = "https://coder.com";
    license = lib.licenses.agpl3Only;
    platforms = [ "x86_64-linux" ];
    mainProgram = "coder";
  };
}
