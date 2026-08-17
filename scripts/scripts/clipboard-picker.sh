#!/usr/bin/env bash
# Replaces noctalia's built-in clipboard UI. The cliphist watcher is started
# from sway's startup list; this is just the picker.
set -euo pipefail
cliphist list | fuzzel --dmenu --prompt='  ' | cliphist decode | wl-copy
