#!/usr/bin/env bash
# Print the number of pending nixpkgs updates, for the noctalia `update-count`
# bar widget (modules/home/noctalia.nix wires this in as customCmdGetNumUpdates).
#
# "Number of updates" does not mean the same thing on NixOS as on Arch or
# Debian: there is no package-by-package upgrade list, there is one input
# revision that everything else follows. So this reports 1 when the flake's
# locked nixpkgs differs from the current nixos-unstable channel revision, and 0
# when they match. That is the honest answer to "is there an update waiting".
#
# Prints a bare integer on stdout and nothing else — the widget does
# parseInt(stdout) and shows -1 if that fails.
set -uo pipefail

FLAKE="${1:-$HOME/nixos-config}"

# NOTE: read .nodes.root.inputs.nixpkgs, NOT .nodes.nixpkgs. The top-level
# "nixpkgs" node in flake.lock is a TRANSITIVE input belonging to some other
# flake (here it is the one lanzaboote and nixpkgs-zed share); the revision this
# system is actually built from is whatever root.inputs.nixpkgs points at.
locked=$(
    jq -r '.nodes[.nodes.root.inputs.nixpkgs].locked.rev // empty' \
        "$FLAKE/flake.lock" 2>/dev/null
)
[ -n "$locked" ] || {
    echo 0
    exit 0
}

latest=$(curl -fsS --max-time 10 https://channels.nixos.org/nixos-unstable/git-revision 2>/dev/null)
# No network, or the channel endpoint is down: report 0 rather than a bogus
# count. A widget that shows "updates available" because the wifi dropped is
# worse than one that shows nothing.
[ -n "$latest" ] || {
    echo 0
    exit 0
}

if [ "$locked" = "$latest" ]; then
    echo 0
else
    echo 1
fi
