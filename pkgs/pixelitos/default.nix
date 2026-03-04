{
  lib,
  fetchFromGitHub,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation {
  pname = "pixelitos-icon-theme";
  version = "20260219";

  src = fetchFromGitHub {
    owner = "ItsZariep";
    repo = "pixelitos-icon-theme";
    tag = "20260219";
    hash = "sha256-YrzymusEFbLNss7svsah2ewwcgskyGtoVSr7vBjT5as=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/icons
    cp -r pixelitos-dark $out/share/icons/
    runHook postInstall
  '';

  meta = {
    description = "Pixel art icon theme for Linux";
    homepage = "https://github.com/ItsZariep/pixelitos-icon-theme";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
}
