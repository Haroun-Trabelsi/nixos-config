#!/usr/bin/env bash
# Back up the Lanzaboote / sbctl Secure Boot PKI (/var/lib/sbctl).
#
# WHY THIS IS NOT IN THE REPO:
#   github.com/Haroun-Trabelsi/nixos-config is PUBLIC. These are the private
#   keys (PK, KEK, db) whose signatures this machine's firmware trusts. Even
#   age-encrypted, publishing them means an attacker has unlimited offline
#   access to the ciphertext, and a single leaked age key would let them sign a
#   bootloader this machine boots. That is strictly worse than the two-minute
#   firmware trip that re-enrolling costs.
#
#   So the blob goes somewhere you control. Removable media or a password
#   manager attachment, not a public git remote.
#
# Losing these keys is survivable but annoying: you re-run `sbctl create-keys`
# and `sbctl enroll-keys --microsoft` in firmware Setup Mode, and every EXISTING
# generation's signature becomes invalid — which matters, because the boot menu
# is your rollback path.
#
# Usage:  sudo ./scripts/recovery/backup-secure-boot-keys.sh [DEST_DIR]
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEST="${1:-$HOME/secure-boot-backup}"

if [ "$(id -u)" -ne 0 ]; then
    echo "error: /var/lib/sbctl/keys/*/*.key are mode 0400 root:root — run with sudo." >&2
    exit 1
fi

# Refuse to write into the repo, whatever the caller passes.
case "$(readlink -f "$DEST")/" in
    "$REPO_ROOT"/*)
        echo "error: $DEST is inside $REPO_ROOT, which is a PUBLIC repository." >&2
        echo "       Pick a destination outside it." >&2
        exit 1
        ;;
esac

[ -d /var/lib/sbctl ] || { echo "error: /var/lib/sbctl does not exist." >&2; exit 1; }

# Recipients come from .sops.yaml, so this automatically picks up the offline
# recovery key once you have added it there.
mapfile -t RECIPIENTS < <(grep -oE 'age1[a-z0-9]{20,}' "$REPO_ROOT/.sops.yaml" | sort -u)
if [ "${#RECIPIENTS[@]}" -eq 0 ]; then
    echo "error: no age recipients found in $REPO_ROOT/.sops.yaml" >&2
    exit 1
fi
if [ "${#RECIPIENTS[@]}" -eq 1 ]; then
    echo "WARNING: only ONE age recipient. If that key is lost this backup is"
    echo "         unreadable — which is the exact failure it exists to prevent."
    echo "         Add an offline recovery recipient to .sops.yaml first."
    echo
fi

install -d -m 700 "$DEST"
OUT="$DEST/sbctl-pki-$(date +%Y%m%d).tar.age"

args=()
for r in "${RECIPIENTS[@]}"; do args+=(-r "$r"); done

# Plaintext never touches disk: tar straight into age.
tar -C /var/lib -cf - sbctl | age "${args[@]}" -o "$OUT"
chmod 600 "$OUT"
chown "${SUDO_UID:-0}:${SUDO_GID:-0}" "$OUT" 2>/dev/null || true

echo "wrote $OUT"
echo "encrypted to ${#RECIPIENTS[@]} recipient(s):"
printf '  %s\n' "${RECIPIENTS[@]}"
echo
echo "NOW MOVE IT OFF THIS MACHINE. A backup on the disk it is backing up is not a backup."
echo "Restore with: ./scripts/recovery/restore-secure-boot-keys.sh $OUT"
