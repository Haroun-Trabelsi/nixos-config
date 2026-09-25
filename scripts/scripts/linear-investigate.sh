#!/usr/bin/env bash
# $mod+I on a Linear issue in Edge: start `claude "/piv-investigate-issue <ID>"`
# in a new workspace of the herdr server on the Coder workspace, then raise the
# herdr window ($mod+C / toggle-herdr) so you can watch it.
#
# The issue id comes from the focused window's title: Linear titles its issue
# pages "ENG-123 <issue title>", and a browser window is titled after its
# active tab. Anchoring the match to the start of the title is what keeps a
# Slack tab mentioning ENG-123 from starting an investigation.
#
# Usage:
#   linear-investigate            # id from the focused window's title
#   linear-investigate ENG-123    # explicit id, skips the title lookup

set -uo pipefail

# Env-overridable so they can be retargeted without a rebuild.
MACHINE="${LINEAR_INVESTIGATE_MACHINE:-haroun}"
REPO="${LINEAR_INVESTIGATE_REPO:-/home/coder/root-for-local}"

notify() { notify-send -a "linear-investigate" "$@"; }
die() {
    notify -u critical "Linear investigate" "$1"
    echo "linear-investigate: $1" >&2
    exit 1
}

id="${1:-}"
if [ -z "$id" ]; then
    title="$(wm title)"
    id="$(printf '%s' "$title" | grep -oE '^[A-Z][A-Z0-9]*-[0-9]+' | head -n1)"
    [ -z "$id" ] && die "Focused window is not a Linear issue: ${title:-no title}"
fi
id="$(printf '%s' "$id" | tr '[:lower:]' '[:upper:]')"

h() { herdr --machine "$MACHINE" "$@"; }

# Bring the herdr window up without toggle-herdr's "already focused -> go back"
# half. setsid so the kitty outlives this script.
show() {
    if wm running herdr-coder; then wm focus herdr-coder; else setsid -f toggle-herdr; fi
}

workspaces="$(h workspace list 2>&1)" ||
    die "Can't reach herdr on '$MACHINE': $workspaces"

# Already investigating this issue? Focus it instead of starting a second
# claude session on the same ticket — a double press should never cost a run.
existing="$(printf '%s' "$workspaces" |
    jq -r --arg l "$id" 'first(.result.workspaces[] | select(.label == $l)) | .workspace_id // empty')"
if [ -n "$existing" ]; then
    h workspace focus "$existing" > /dev/null
    show
    notify "Linear investigate" "$id is already open — focused it."
    exit 0
fi

created="$(h workspace create --cwd "$REPO" --label "$id" --focus 2>&1)" ||
    die "Couldn't create a herdr workspace for $id: $created"
pane="$(printf '%s' "$created" | jq -r '.result.root_pane.pane_id // empty')"
[ -z "$pane" ] && die "herdr returned no pane for $id: $created"

# `pane run` types the command and Enter into the new shell, which buffers it
# until the prompt is up. claude runs inside that shell, so quitting it leaves
# a prompt in the repo — no trailing `exec zsh -i` needed like linear-plan's.
h pane run "$pane" "claude \"/piv-investigate-issue $id\"" > /dev/null ||
    die "Created workspace $id but couldn't start claude in $pane."

show
notify "Linear investigate" "$id → herdr on $MACHINE"
