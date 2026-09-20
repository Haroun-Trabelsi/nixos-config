#!/usr/bin/env bash
# Window class is `bitwarden`, lowercase — verified from `hyprctl clients`, not
# from the .desktop file, which ships no StartupWMClass at all.
ident=bitwarden
match='[B]itwarden/resources/app.asar'   # bracket: never match our own cmdline

# Normal case: a window exists, so focus it / go back, like every other toggle.
if wm running "$ident"; then
  exec toggle-app "$ident" bitwarden
fi

# No window — but Bitwarden may still be alive in its tray icon. In that state a
# second `bitwarden` hits Electron's single-instance lock and exits immediately
# WITHOUT restoring the window, which is how this bind turned into a silent
# no-op: the app was running, invisible, and unreachable.
#
# Restarting is the only recovery that does not depend on a tray icon being
# present and clickable. It costs an unlocked session, which a password manager
# should be relaxed about losing.
if pgrep -f "$match" >/dev/null 2>&1; then
  pkill -f "$match"
  # Wait for the single-instance lock to actually clear, or the relaunch races
  # the dying process and no-ops exactly as before.
  for _ in $(seq 1 40); do
    pgrep -f "$match" >/dev/null 2>&1 || break
    sleep 0.25
  done
fi

exec bitwarden
