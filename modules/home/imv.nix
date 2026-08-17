{ ... }:
{
  # imv ships imv.desktop and imv-dir.desktop with NoDisplay=true. KDE's
  # KApplicationTrader (what Dolphin uses to resolve a handler) filters out
  # NoDisplay entries, so Dolphin ignored the image association entirely and
  # fell back to the next claimant. Ship a visible entry of our own instead.
  #
  # Deliberately NOT named imv-dir: that would collide with the imv package's
  # own entry inside home-path/share/applications, and with equal derivation
  # priority the winner is just whichever comes first in home.packages.
  # xdg-mimes.nix points the image types at this name.
  xdg.desktopEntries.imv-viewer = {
    name = "imv";
    genericName = "Image Viewer";
    comment = "Fast image viewer | opens every image in the directory";
    exec = "imv-dir %F";
    icon = "multimedia-photo-viewer";
    terminal = false;
    categories = [
      "Graphics"
      "2DGraphics"
      "Viewer"
    ];
    mimeType = [
      "image/avif"
      "image/bmp"
      "image/gif"
      "image/heic"
      "image/heif"
      "image/jpeg"
      "image/jpg"
      "image/jxl"
      "image/png"
      "image/qoi"
      "image/svg+xml"
      "image/tiff"
      "image/vnd.microsoft.icon"
      "image/webp"
      "image/x-bmp"
      "image/x-farbfeld"
      "image/x-png"
    ];
  };
}
