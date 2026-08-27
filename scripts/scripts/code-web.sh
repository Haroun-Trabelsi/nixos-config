#!/usr/bin/env bash
# VS Code in the browser, running entirely on the Coder workspace.
#
# Why this exists: VS Code's extension ecosystem is inseparable from its
# Electron/Node extension host, so there is no native "light VS Code". The next
# best thing for battery is to run the whole editor REMOTELY — extension host,
# language servers, tsserver, file watchers — and keep only a browser tab local,
# in a browser that is already open. That removes an entire Electron runtime and
# all the language tooling from the laptop.
set -euo pipefail

WS=haroun
AGENT=haroun.main
REMOTE_PORT=8090
LOCAL_PORT=8091
CODER=/usr/local/bin/coder
URL="http://localhost:${LOCAL_PORT}/"

note() { command -v notify-send >/dev/null && notify-send "code-web" "$1" || echo "$1"; }

# 1. Workspace running? (no TTL is set on it, so this is only for a manual stop)
if ! $CODER list -o json 2>/dev/null \
     | jq -e --arg w "$WS" '.[] | select(.name==$w and .latest_build.status=="running")' >/dev/null; then
  note "starting workspace $WS…"
  $CODER start "$WS" --yes
fi

# 2. code-server alive in the workspace? Started under tmux deliberately: the
#    workspace has no systemd (PID 1 is the coder agent), so tmux is what makes
#    it survive an SSH disconnect — same reason the autopilot/ap-watch sessions
#    there are weeks old.
$CODER ssh "$AGENT" -- \
  'tmux has-session -t code-server 2>/dev/null || tmux new-session -d -s code-server code-server' \
  >/dev/null 2>&1 || true

# 3. Local tunnel. Coder has no wildcard DNS configured, so a port-forward is the
#    reliable path rather than a https://PORT--agent--ws--user.<host>/ URL.
#    Local 8091, not 8090: something else on this laptop already binds 8090.
if ! ss -tln 2>/dev/null | grep -q ":${LOCAL_PORT} "; then
  setsid "$CODER" port-forward "$WS" --tcp "${LOCAL_PORT}:${REMOTE_PORT}" >/dev/null 2>&1 &
  for _ in $(seq 1 30); do
    ss -tln 2>/dev/null | grep -q ":${LOCAL_PORT} " && break
    sleep 0.5
  done
fi

# 4. Focus an existing tab's window if the browser is already up, else open it.
exec thorium --app="$URL"
