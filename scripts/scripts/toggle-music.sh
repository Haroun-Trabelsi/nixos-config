#!/usr/bin/env bash
# Was toggle-spotify (Electron). Now toggles the mpd TUI in its own terminal.
# mpd itself is socket-activated, so it starts on first connect and nothing
# runs when no music is playing.
exec toggle-app app_id rmpc kitty --class=rmpc rmpc
