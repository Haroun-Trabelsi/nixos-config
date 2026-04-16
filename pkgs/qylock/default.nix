{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  makeWrapper,
  quickshell,
  bash,
  coreutils,
  systemd,
  util-linux,
  psmisc,
  qt6,
  gst_all_1,
}:
let
  # Qt6 multimedia backend on Linux uses GStreamer; the pixel-* themes ship
  # .mp4 backgrounds so we need at least the "good" + "libav" plugin sets.
  gstPluginPath = lib.makeSearchPath "lib/gstreamer-1.0" [
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-libav
  ];
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "qylock";
  version = "0-unstable-2026-04-16";

  src = fetchFromGitHub {
    owner = "Darkkal44";
    repo = "qylock";
    rev = "c691cb286a3e7b74735de1be94bf3048f6cacbcd";
    hash = "sha256-LJ5bKxo8WVV01pSyP/MosMBtD5iA+0vBxi3QOSvi7+c=";
  };

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/qylock
    cp -r quickshell-lockscreen $out/share/qylock/
    cp -r themes               $out/share/qylock/

    # lock.sh expects a themes_link symlink next to itself
    ln -sfn ../themes $out/share/qylock/quickshell-lockscreen/themes_link

    chmod +x $out/share/qylock/quickshell-lockscreen/lock.sh

    mkdir -p $out/bin
    makeWrapper $out/share/qylock/quickshell-lockscreen/lock.sh $out/bin/qylock \
      --prefix PATH : ${
        lib.makeBinPath [
          quickshell
          bash
          coreutils
          systemd
          util-linux
          psmisc
        ]
      } \
      --prefix QML2_IMPORT_PATH : "${qt6.qtmultimedia}/${qt6.qtbase.qtQmlPrefix}" \
      --prefix QML2_IMPORT_PATH : "${qt6.qt5compat}/${qt6.qtbase.qtQmlPrefix}" \
      --prefix QT_PLUGIN_PATH : "${qt6.qtmultimedia}/${qt6.qtbase.qtPluginPrefix}" \
      --prefix QT_PLUGIN_PATH : "${qt6.qt5compat}/${qt6.qtbase.qtPluginPrefix}" \
      --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "${gstPluginPath}"

    runHook postInstall
  '';

  passthru = {
    themesDir = "share/qylock/themes";
    hollowKnightVideo = "share/qylock/themes/pixel-hollowknight/bg.mp4";
  };

  meta = {
    description = "Themed Quickshell-based lockscreen (qylock)";
    homepage = "https://github.com/Darkkal44/qylock";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
    mainProgram = "qylock";
  };
})
