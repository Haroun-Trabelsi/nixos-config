{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  zlib,
  ...
}:
# @salesforce/cli — the `sf` / `sfdx` CLI.
#
# This was installed imperatively with `npm i -g` into ~/.npm-global, which made
# it invisible to nix: not in the closure, never garbage-collected, not rebuilt
# when nixpkgs moved, and gone on a fresh install with only a README line to say
# it had ever been there. It is not in nixpkgs at any version.
#
# Salesforce publish a STANDALONE tarball per version — bundled node, all deps
# vendored — with a sha256 in a public build manifest, which is what makes this
# pinnable rather than a moving target:
#
#   curl -s https://developer.salesforce.com/media/salesforce-cli/sf/channels/stable/sf-linux-x64-buildmanifest
#
# To update: read that manifest, then bump version + sha + hash below. The hash
# in the manifest is hex; convert with
#   nix hash convert --hash-algo sha256 --to sri <hex>
let
  version = "2.150.6";
  build = "c049970";
in
stdenv.mkDerivation {
  pname = "salesforce-cli";
  inherit version;

  src = fetchurl {
    url = "https://developer.salesforce.com/media/salesforce-cli/sf/versions/${version}/${build}/sf-v${version}-${build}-linux-x64.tar.xz";
    hash = "sha256-//Df9NIkRXIoWoV6XETqUJfukw/ZO5PHsMa5WFcHLQQ=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  # The bundled node binary is a normal dynamically linked ELF.
  buildInputs = [
    stdenv.cc.cc.lib
    zlib
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/libexec/sf" "$out/bin"
    cp -r . "$out/libexec/sf/"

    # bin/sf and bin/sfdx are shell wrappers that exec the vendored node.
    for prog in sf sfdx; do
      if [ -e "$out/libexec/sf/bin/$prog" ]; then
        chmod +x "$out/libexec/sf/bin/$prog"
        ln -s "$out/libexec/sf/bin/$prog" "$out/bin/$prog"
      fi
    done

    runHook postInstall
  '';

  # The vendored node is prebuilt for a generic glibc; don't let the fixup phase
  # strip it, and don't fail on the many optional native modules that ship
  # without their platform deps.
  dontStrip = true;
  autoPatchelfIgnoreMissingDeps = true;

  meta = {
    description = "Salesforce CLI (sf/sfdx), from the upstream standalone build";
    homepage = "https://developer.salesforce.com/tools/salesforcecli";
    license = lib.licenses.bsd3;
    platforms = [ "x86_64-linux" ];
    mainProgram = "sf";
  };
}
