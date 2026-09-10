#!/usr/bin/env bash
# Restore the sbctl Secure Boot PKI from a backup made by
# ./backup-secure-boot-keys.sh.
#
# Usage:  sudo ./scripts/recovery/restore-secure-boot-keys.sh BLOB [IDENTITY]
#
# IDENTITY defaults to ~/.config/sops/age/keys.txt; pass your offline recovery
# identity instead if that is the one you still have.
set -euo pipefail

BLOB="${1:?usage: restore-secure-boot-keys.sh BLOB [IDENTITY]}"
IDENTITY="${2:-${SUDO_USER:+/home/$SUDO_USER}/.config/sops/age/keys.txt}"

[ "$(id -u)" -eq 0 ] || { echo "error: run with sudo (writes /var/lib/sbctl)." >&2; exit 1; }
[ -r "$BLOB" ] || { echo "error: cannot read $BLOB" >&2; exit 1; }
[ -r "$IDENTITY" ] || { echo "error: cannot read identity $IDENTITY" >&2; exit 1; }

if [ -e /var/lib/sbctl ]; then
    echo "/var/lib/sbctl already exists. Moving it aside rather than overwriting:"
    mv -v /var/lib/sbctl "/var/lib/sbctl.before-restore-$(date +%s)"
fi

age -d -i "$IDENTITY" "$BLOB" | tar -C /var/lib -xf -
echo "restored /var/lib/sbctl"
echo
echo "Next: rebuild so Lanzaboote re-signs with these keys:"
echo "  sudo nixos-rebuild switch --flake .#portable"
echo "Verify enrolment state with:  sbctl status"
