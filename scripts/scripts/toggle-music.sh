#!/usr/bin/env bash
# Desktop has Spotify (spicetify-themed); laptop has mpd + rmpc. Pick whichever
# this machine actually installed rather than branching on hostname.
if command -v spotify >/dev/null 2>&1; then
  exec toggle-app Spotify spotify
else
  exec toggle-app rmpc kitty --class=rmpc rmpc
fi
