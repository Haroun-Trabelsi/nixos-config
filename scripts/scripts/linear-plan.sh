#!/usr/bin/env bash
# One-click "plan this Linear issue with Claude Code".
#
# Spawns a kitty in the root-for-local checkout running `claude "/plan-issue <ID>"`.
# Entry points, all funnelling here:
#   * browser bookmarklet -> claude-plan://ENG-123 -> linear-plan.desktop -> this
#   * $mod SHIFT, P       -> no argument, so the issue id is read from the clipboard
#   * app launcher entry  -> same clipboard path
#
# Placement: work terminals live on WS8, but a plan session is a long-lived thing
# and four claude TUIs on one workspace is already unreadable, so the fifth and
# beyond overflow to WS5. Anything past that keeps stacking on WS5 (no third tier —
# by then you have too many sessions open, not a layout problem).
#
# Usage:
#   linear-plan                       # id from clipboard
#   linear-plan ENG-123
#   linear-plan https://linear.app/journey-ai/issue/ENG-123/some-slug
#   linear-plan claude-plan://ENG-123 # what the browser hands us
#   linear-plan --silent ENG-123      # spawn without yanking focus off the browser
#   linear-plan --dry-run ENG-123     # same window, same placement, no claude session

set -uo pipefail

# Env-overridable so the placement rule can be retuned (or tested) without a rebuild.
PRIMARY_WS="${LINEAR_PLAN_WS:-8}"
OVERFLOW_WS="${LINEAR_PLAN_OVERFLOW_WS:-5}"
MAX_ON_PRIMARY="${LINEAR_PLAN_MAX:-4}"
REPO="${LINEAR_PLAN_REPO:-$HOME/work/root-for-local}"

silent=""
dry=""
while :; do
    case "${1:-}" in
        --silent | -s)
            silent=" silent"
            shift
            ;;
        --dry-run | -n)
            dry=1
            shift
            ;;
        *) break ;;
    esac
done

notify() { notify-send -a "linear-plan" "$@"; }
die() {
    notify -u critical "Linear plan" "$1"
    echo "linear-plan: $1" >&2
    exit 1
}

raw="${1:-}"
# No argument (keybind / launcher): fall back to whatever is on the clipboard, so
# "copy issue link" in Linear then one keypress works the same as the bookmarklet.
if [ -z "$raw" ]; then
    raw="$(wl-paste --no-newline 2> /dev/null)"
    [ -z "$raw" ] && die "No issue given and the clipboard is empty."
fi

# Strip our own scheme before pattern matching. Chromium lowercases the authority
# of claude-plan://ENG-123 and may append a trailing slash, hence the tr below.
raw="${raw#claude-plan://}"
raw="${raw#claude-plan:}"
raw="${raw%/}"

# Prefer the canonical Linear URL shape; a slug like "fix-eng-1-regression" would
# otherwise be a false positive for the loose match.
id="$(printf '%s' "$raw" | grep -oiE '/issue/[a-z]+-[0-9]+' | head -n1 | grep -oiE '[a-z]+-[0-9]+')"
[ -z "$id" ] && id="$(printf '%s' "$raw" | grep -oiE '[a-z]+-[0-9]+' | head -n1)"
[ -z "$id" ] && die "No Linear issue id found in: $raw"
id="$(printf '%s' "$id" | tr '[:lower:]' '[:upper:]')"

[ -d "$REPO" ] || die "$REPO does not exist."

title="plan $id"

tree="$(swaymsg -t get_tree)"

# Already planning this issue? Focus that window instead of starting a second
# session on the same ticket — a double click should never cost a second plan run.
addr="$(printf '%s' "$tree" |
    jq -r --arg t "$title" 'first(recurse(.nodes[]?,.floating_nodes[]?) | select(.name == $t)) | .id // empty')"
if [ -n "$addr" ]; then
    swaymsg "[con_id=$addr] focus"
    notify "Linear plan" "$id is already open — focused it."
    exit 0
fi

count="$(printf '%s' "$tree" |
    jq --argjson ws "$PRIMARY_WS" '[recurse(.nodes[]?) | select(.type=="workspace" and .num==$ws) | recurse(.nodes[]?,.floating_nodes[]?) | select(.pid?)] | length')"
ws="$PRIMARY_WS"
[ "${count:-0}" -ge "$MAX_ON_PRIMARY" ] && ws="$OVERFLOW_WS"

# kitty's --title wins over anything the program inside sets, which is what makes
# the dedup check above reliable against a full-screen TUI.
#
# claude lives in ~/.local/bin (native installer), which the desktop session's PATH
# does not have — so go through an interactive zsh to pick up .zshrc's PATH. The
# trailing `exec zsh -i` leaves a usable shell in the repo when claude exits instead
# of the window vanishing with the transcript.
inner="claude \"/plan-issue $id\"; exec zsh -i"
[ -n "$dry" ] && inner="echo \"[dry run] claude \\\"/plan-issue $id\\\"\"; exec zsh -i"

# sway cannot exec onto a named workspace, so switch there first.
swaymsg workspace number "$ws"
swaymsg exec -- kitty --directory "$REPO" --title "$title" zsh -i -c "$inner"

notify "Linear plan" "$id → workspace $ws${dry:+ (dry run)}"
