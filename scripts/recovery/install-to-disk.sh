#!/usr/bin/env bash
# Install this config onto another disk, from the running system. The fast path.
#
# WHY NOT THE ISO: the ISO is the right tool when this machine is DEAD. While it
# is alive and booted, it is the slow way round — nixos-install from a live ISO
# re-fetches or rebuilds the whole closure. Installing from here reuses the local
# /nix/store, so most of the "build" is a local copy.
#
# WHY NOT dd/CLONE: it copies every used byte and duplicates every filesystem
# UUID. Two disks claiming the same root UUID is precisely the ambiguity that
# by-uuid mounts exist to prevent, and you would have to regenerate them and
# edit hardware-shared.nix afterwards anyway — which is the very step this
# script automates.
#
# Usage:
#   # the Vivobook's internal NVMe, replacing Windows — run ON the Vivobook,
#   # booted from the portable SSD:
#   sudo ./scripts/recovery/install-to-disk.sh --host vivobook /dev/nvme0n1
#
#   # another copy of the portable two-machine disk:
#   sudo ./scripts/recovery/install-to-disk.sh --host portable /dev/sdX
#
#   --host NAME       which hosts/<NAME> to install. Default: portable
#   --dry-run         print each step without touching anything
#   --swap / --data   portable only: also create the optional swap / exfat
#                     partitions (both off by default)
#   --force-machine   skip the DMI check. You will be asked to justify this to
#                     yourself when the wrong disk is gone.
#
# THE DMI CHECK: hosts/<NAME>/expect-dmi, when present, holds a pattern that
# must appear in this machine's DMI strings. It exists because "the Windows
# disk" is not a unique thing — the tower has two NTFS disks of its own, and
# /dev/nvme0n1 is the internal drive on nearly every machine including that one.
# Running the vivobook install from the tower would have formatted the tower.
# The check fails CLOSED.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MNT=/mnt
DRY=0
WANT_SWAP=0
WANT_DATA=0
FORCE_MACHINE=0
HOST=portable
DEVICE=""

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run) DRY=1 ;;
        --swap) WANT_SWAP=1 ;;
        --data) WANT_DATA=1 ;;
        --force-machine) FORCE_MACHINE=1 ;;
        --host)
            HOST="${2:?--host needs a name}"
            shift
            ;;
        -h | --help)
            sed -n '2,24p' "${BASH_SOURCE[0]}"
            exit 0
            ;;
        /dev/*) DEVICE="$1" ;;
        *)
            echo "error: unexpected argument '$1'" >&2
            exit 1
            ;;
    esac
    shift
done

die() {
    echo "error: $*" >&2
    exit 1
}
run() { if [ "$DRY" -eq 1 ]; then printf 'would run:'; printf ' %q' "$@"; echo; else "$@"; fi; }

[ -n "$DEVICE" ] || die "no target device. Usage: $0 [--dry-run] /dev/sdX"
# root is only needed to actually do anything — --dry-run stays usable without
# it, which is what makes the plan reviewable before you hand it a disk.
[ "$DRY" -eq 1 ] || [ "$(id -u)" -eq 0 ] ||
    die "run with sudo (partitions disks, writes the target store)"
[ -b "$DEVICE" ] || die "$DEVICE is not a block device"
[ -d "$REPO_ROOT/hosts/$HOST" ] || die "no such host: hosts/$HOST"
[ -f "$REPO_ROOT/hosts/$HOST/disko.nix" ] || die "hosts/$HOST has no disko.nix"

# ── Is this even the right computer? ────────────────────────────────────────
EXPECT_FILE="$REPO_ROOT/hosts/$HOST/expect-dmi"
if [ -f "$EXPECT_FILE" ]; then
    pattern=$(tr -d '\n' < "$EXPECT_FILE")
    dmi=""
    for f in product_name product_family board_name sys_vendor; do
        dmi="$dmi $(cat "/sys/class/dmi/id/$f" 2>/dev/null || true)"
    done
    if printf '%s' "$dmi" | grep -qi -- "$pattern"; then
        echo "Machine check: DMI matches '$pattern' — this is a hosts/$HOST machine."
    elif [ "$FORCE_MACHINE" -eq 1 ]; then
        echo "Machine check: DMI does NOT match '$pattern', overridden with --force-machine."
        echo "               DMI here:$dmi"
    else
        echo "error: this does not look like a hosts/$HOST machine." >&2
        echo "       hosts/$HOST/expect-dmi wants:  $pattern" >&2
        echo "       this machine reports:         $dmi" >&2
        echo "" >&2
        echo "       Refusing. \"The Windows disk\" is not unique — /dev/nvme0n1 is" >&2
        echo "       the internal drive on nearly every machine, and formatting the" >&2
        echo "       wrong one is not recoverable. Run this on the target machine," >&2
        echo "       or pass --force-machine if you are certain." >&2
        exit 1
    fi
fi

# Refuse to eat the disk we are running from.
running_disk=$(lsblk -no PKNAME "$(findmnt -no SOURCE /)" 2>/dev/null | head -1)
target_disk=$(basename "$(readlink -f "$DEVICE")")
[ "$running_disk" != "$target_disk" ] ||
    die "$DEVICE (/dev/$target_disk) is the disk this system is running from. Pick the other one."

# hosts/portable shares its hardware file with the tower, hence the name.
case "$HOST" in
    portable) HW_FILE=hardware-shared.nix ;;
    *) HW_FILE=hardware.nix ;;
esac
[ -f "$REPO_ROOT/hosts/$HOST/$HW_FILE" ] || die "hosts/$HOST/$HW_FILE not found"

echo "Installing hosts/$HOST onto $DEVICE"
lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINT "$DEVICE" || true
echo

# ── Phase 1: partition and format ───────────────────────────────────────────
# Two phases rather than one `disko-install`, because disko-install would write
# hardware-shared.nix verbatim and the new disk would boot a config naming the
# OLD disk's UUIDs — which is a non-boot, or worse, silently mounts the old disk
# if both are attached. Formatting first means the real UUIDs are knowable
# before the config is installed.
DISKO_ARGS=(--mode destroy,format,mount --argstr device "$DEVICE"
    --root-mountpoint "$MNT" "$REPO_ROOT/hosts/$HOST/disko.nix")
[ "$WANT_SWAP" -eq 1 ] && DISKO_ARGS+=(--arg enableSwap true)
[ "$WANT_DATA" -eq 1 ] && DISKO_ARGS+=(--arg enableDataPartition true)

if [ "$DRY" -eq 1 ]; then
    printf 'would run: disko'
    printf ' %q' "${DISKO_ARGS[@]}"
    echo
else
    echo "This will DESTROY everything on $DEVICE."
    read -r -p "Type the device path again to confirm: " confirm
    [ "$confirm" = "$DEVICE" ] || die "mismatch, aborting"
    nix run "$REPO_ROOT#disko" -- "${DISKO_ARGS[@]}"
fi

# ── Phase 2: discover the new UUIDs ─────────────────────────────────────────
if [ "$DRY" -eq 0 ]; then
    root_uuid=$(findmnt -no UUID "$MNT")
    boot_uuid=$(findmnt -no UUID "$MNT/boot")
    swap_uuid=$(lsblk -no UUID,FSTYPE "$DEVICE" | awk '$2 == "swap" { print $1; exit }')
    [ -n "$root_uuid" ] || die "could not read the new root UUID"
    [ -n "$boot_uuid" ] || die "could not read the new ESP UUID"
    echo "New UUIDs — root: $root_uuid  boot: $boot_uuid  swap: ${swap_uuid:-<none>}"
fi

# ── Phase 3: a copy of the repo with those UUIDs ────────────────────────────
WORK=$(mktemp -d /tmp/install-to-disk.XXXXXX)
trap 'rm -rf "$WORK"' EXIT
run cp -a "$REPO_ROOT/." "$WORK/"

if [ "$DRY" -eq 0 ]; then
    HW="$WORK/hosts/$HOST/$HW_FILE"
    sed -i "0,/by-uuid/{s|/dev/disk/by-uuid/[0-9a-fA-F-]*|/dev/disk/by-uuid/$root_uuid|}" "$HW"
    sed -i "/fileSystems.\"\/boot\"/,/};/{s|/dev/disk/by-uuid/[0-9A-Fa-f-]*|/dev/disk/by-uuid/$boot_uuid|}" "$HW"
    if [ -n "$swap_uuid" ]; then
        sed -i "/swapDevices/,/];/{s|/dev/disk/by-uuid/[0-9a-fA-F-]*|/dev/disk/by-uuid/$swap_uuid|}" "$HW"
    else
        python3 - "$HW" <<'PYEOF'
import re, sys
path = sys.argv[1]
src = open(path).read()

# Already empty (hosts/vivobook declares `swapDevices = [ ];` outright, since
# that layout never creates a swap partition) — nothing to do. Without this the
# multi-line pattern below fails to match and aborts the install.
if re.search(r"^  swapDevices = \[ *\];$", src, flags=re.M):
    print("swapDevices already empty, leaving it")
    sys.exit(0)

# Anchor the terminator to a line of exactly two spaces + "];" — a bare
# non-greedy match stops at the "];" closing the inner options list and leaves
# broken Nix behind.
out, n = re.subn(r"^  swapDevices = \[.*?^  \];$", "  swapDevices = [ ];",
                 src, count=1, flags=re.S | re.M)
if n != 1:
    sys.exit("could not rewrite swapDevices in " + path)
open(path, "w").write(out)
PYEOF
    fi
    echo "Rewrote mounts in the install copy:"
    grep -n "by-uuid\|swapDevices" "$HW"
    # Flakes only see tracked files, and a dirty/absent git tree breaks eval.
    git -C "$WORK" init -q 2>/dev/null || true
    git -C "$WORK" add -A
    git -C "$WORK" -c user.email=install@localhost -c user.name=install \
        commit -qm "install: mount UUIDs for $DEVICE" || true
fi

# ── Phase 4: install ────────────────────────────────────────────────────────
run nixos-install --root "$MNT" --flake "$WORK#$HOST" --no-root-password --no-channel-copy

# ── Phase 5: the things nix cannot carry ────────────────────────────────────
# Lanzaboote signs with pkiBundle = /var/lib/sbctl, resolved on the TARGET. A
# fresh disk has none, so the bootloader would be installed unsigned and the
# firmware would reject it — discovered only at boot.
if [ -d /var/lib/sbctl ]; then
    run mkdir -p "$MNT/var/lib"
    run cp -a /var/lib/sbctl "$MNT/var/lib/"
    echo "Copied /var/lib/sbctl so Lanzaboote can sign on the new disk."
else
    echo "WARNING: no /var/lib/sbctl here. The new disk will need Secure Boot"
    echo "         disabled until you run 'sbctl create-keys' and enroll them."
fi

# programs.nh.flake points at ~/nixos-config, so the repo has to be there.
run mkdir -p "$MNT/home/fantasy"
run cp -a "$WORK" "$MNT/home/fantasy/nixos-config"
run chown -R 1000:100 "$MNT/home/fantasy/nixos-config"

cat <<'POST'

────────────────────────────────────────────────────────────────────────
Done. Two things nix cannot do for you:

1. The age key. Put your off-machine copy at
       /home/fantasy/.config/sops/age/keys.txt      (chmod 600, owned by you)
   on the new root. Without it every secret is unavailable and
   modules/home/sops-env.nix silently writes nothing. It is deliberately
   not copied by this script.

2. tailscale up (or add tailscale_auth_key to secrets.yaml), coder login,
   browser sign-ins. See secrets/RECOVERY.md.

The mount UUIDs are already correct in the installed copy of the repo.
────────────────────────────────────────────────────────────────────────
POST
