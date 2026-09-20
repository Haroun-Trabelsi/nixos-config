#!/usr/bin/env bash
# Desktop has Spotify (spicetify-themed); laptop has mpd + rmpc. Pick whichever
# this machine actually installed rather than branching on hostname.
#
# The ident is "spotify" LOWERCASE: that is the Wayland app_id Spotify actually
# reports (verified with `hyprctl clients -j`). `wm running` compares with
# exact string equality, so the old "Spotify" never matched a live window and
# every Super+S launched a SECOND Spotify instead of focusing the first.
if command -v spotify >/dev/null 2>&1; then
  exec toggle-app spotify spotify
else
  exec toggle-app rmpc kitty --class=rmpc rmpc
fi
