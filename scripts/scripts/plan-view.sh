#!/usr/bin/env bash
# Show an implementation plan fullscreen, rendered, in glow.
#
# Modes:
#   plan-view <file.md>   show that file
#   plan-view             show the newest plan in the current repo (and its worktrees)
#   plan-view --hook      Claude Code Stop-hook mode: reads the hook JSON on stdin and
#                         shows a plan only if one was just written. Silent otherwise.
#
# Hook mode is what makes "/plan-issue finishes -> the plan is on screen" automatic.
# /plan-issue writes to <root-worktree>/docs/plans/, which is not the checkout the
# session started in, so the candidate directories come from `git worktree list`
# rather than from the cwd alone.
#
# Two things keep hook mode quiet, since Stop fires after every single turn in every
# session:
#   * the plan must have been touched in the last $RECENT_MIN minutes;
#   * each path is shown at most once, recorded in $STATE. So a plan revised later in
#     the run does not pop up again, and /implement-plan ticking checkboxes in an
#     already-seen plan never pops up at all. Re-read the current version any time
#     with a bare `plan-view`.

set -uo pipefail

RECENT_MIN="${PLAN_VIEW_RECENT_MIN:-10}"
WRAP="${PLAN_VIEW_WRAP:-110}"
STATE="${XDG_CACHE_HOME:-$HOME/.cache}/plan-view/shown"

# Every plans dir reachable from a checkout: the main tree plus every worktree.
plan_dirs() {
    local repo="$1" wt
    while read -r wt; do
        [ -d "$wt/docs/plans" ] && printf '%s\n' "$wt/docs/plans"
    done < <(git -C "$repo" worktree list --porcelain 2> /dev/null |
        awk '/^worktree /{print $2}')
    # Not a git repo (or no worktrees): still honour a plans dir under the cwd.
    [ -d "$repo/docs/plans" ] &&
        ! git -C "$repo" rev-parse --git-dir > /dev/null 2>&1 &&
        printf '%s\n' "$repo/docs/plans"
}

# Newest *.md across those dirs. $1 = repo, $2 = optional `find -newermt` cutoff.
# The dir has to precede find's expression, so each is walked in turn and the
# mtime-prefixed results are ranked together.
newest_plan() {
    local repo="$1" cutoff="${2:-}" d
    while read -r d; do
        [ -n "$d" ] || continue
        if [ -n "$cutoff" ]; then
            find "$d" -maxdepth 1 -name '*.md' -newermt "$cutoff" \
                -printf '%T@ %p\n' 2> /dev/null
        else
            find "$d" -maxdepth 1 -name '*.md' -printf '%T@ %p\n' 2> /dev/null
        fi
    done < <(plan_dirs "$repo") | sort -rn | head -n1 | cut -d' ' -f2-
}

show() {
    local file="$1" title
    title="plan: $(basename "$file")"

    # No compositor (headless / ssh / cron run): render inline instead of failing.
    if [ -z "${SWAYSOCK:-}" ] || ! command -v swaymsg > /dev/null; then
        glow -w "$WRAP" "$file"
        return
    fi

    # Already on screen? Focus it rather than stacking a second copy.
    local con
    con="$(swaymsg -t get_tree |
        jq -r --arg t "$title" 'first(recurse(.nodes[]?,.floating_nodes[]?) | select(.name == $t)) | .id // empty')"
    if [ -n "$con" ]; then
        swaymsg "[con_id=$con] focus"
        return
    fi

    # Fullscreen on the active workspace: the point is that the plan is in front of
    # you the moment it is ready. `q` closes it.
    #
    # background_opacity is overridden per-window because kitty's global 0.66 puts
    # the wallpaper behind the prose, and this window exists to be read.
    # rules.nix fullscreens anything titled "plan: *"; kitty's --title wins over
    # whatever glow sets, which is what makes the dedup check above reliable.
    swaymsg exec -- kitty -o background_opacity=1.0 --title "$title" glow -p -w "$WRAP" "$file"
}

if [ "${1:-}" = "--hook" ]; then
    cwd="$(jq -r '.cwd // empty' 2> /dev/null)"
    [ -z "$cwd" ] && exit 0
    [ -d "$cwd" ] || exit 0

    plan="$(newest_plan "$cwd" "-$RECENT_MIN minutes")"
    [ -z "$plan" ] && exit 0

    mkdir -p "$(dirname "$STATE")"
    touch "$STATE"
    grep -qxF -- "$plan" "$STATE" && exit 0
    printf '%s\n' "$plan" >> "$STATE"

    show "$plan"
    exit 0 # never let a viewer failure block the session
fi

if [ -n "${1:-}" ]; then
    [ -f "$1" ] || {
        echo "plan-view: no such file: $1" >&2
        exit 1
    }
    show "$1"
    exit 0
fi

plan="$(newest_plan "$PWD")"
[ -z "$plan" ] && {
    echo "plan-view: no plans found under $PWD or its worktrees" >&2
    exit 1
}
show "$plan"
