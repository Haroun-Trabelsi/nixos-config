{ config, ... }:
{
  # The wallpaper is VENDORED into this repo (assets/wallpapers/) rather than
  # referenced from ~/Downloads. A path under Downloads is not a configuration
  # source: it is a junk drawer that gets cleaned out, and pointing the shell at
  # one would mean the desktop silently loses its background on a machine that
  # had not happened to download the same file. 2.5 MB of JPEG is a cheap price
  # for the config being self-contained and reproducible on both machines.
  #
  # Upstream file was ~/Downloads/wallapper.jpg; the misspelling is not carried
  # into the repo.
  home.file."Pictures/Wallpapers/wallpaper.jpg".source = ../../assets/wallpapers/wallpaper.jpg;
}
