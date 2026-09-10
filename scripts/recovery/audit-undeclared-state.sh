#!/usr/bin/env bash
# Report mutable state that this config does NOT declare.
#
# This is impermanence's discipline without impermanence's risk. Root-on-tmpfs
# tells you what you forgot to declare by DELETING it at the next reboot; this
# script tells you the same thing by reading the disk, so you can build the
# persist list before anything is mounted or wiped.
#
# Run it before adopting nix-community/impermanence, and again afterwards to
# check the list is complete.
#
# Usage:  ./scripts/recovery/audit-undeclared-state.sh
#         sudo ./scripts/recovery/audit-undeclared-state.sh   # sizes under /var/lib
set -uo pipefail

# ── The persist set ──────────────────────────────────────────────────────────
# Paths that MUST survive a reboot. Anything not listed here is either
# disposable or an oversight — that is the whole point of the exercise.
#
# The first four are load-bearing in ways that are not obvious:
#   sbctl      Lanzaboote's pkiBundle. Lose it and Secure Boot breaks on the
#              tower, recoverable only with a firmware trip.
#   nixos      the uid/gid map. Lose it and users get renumbered, which
#              scrambles ownership of everything in /home.
#   alsa       hardware.alsa.enablePersistence = true writes here.
#   upower     battery history — the evidence behind the percentageAction
#              reasoning in machines/laptop/default.nix.
SYSTEM_PERSIST=(
    sbctl NetworkManager bluetooth nixos alsa upower systemd tailscale
    tlp OpenRGB udisks2 AccountsService lastlog misc logrotate.status private
)

# Services that are NOT enabled in this config. State here is left over from
# something that was removed, and is pure noise in a persist list.
SYSTEM_ORPHANED=(
    flatpak docker ollama lightdm lightdm-data plymouth
    power-profiles-daemon libvirt qemu machines portables colord cups
)

HOME_PERSIST=(
    .ssh .config .local .mozilla .zsh_history .zsh .gnupg .pki
    nixos-config work Documents Music Pictures Videos Downloads
)

# Deliberately disposable — the space impermanence reclaims for free.
HOME_DISPOSABLE=(
    .cache .npm .zcompdump .java .dotnet .texlive2025
)

# `du` fails on root-only paths but `cut` still succeeds, so `||` never fires —
# capture the value and default it instead.
size() {
    local s
    s=$(du -sh "$1" 2>/dev/null | cut -f1)
    echo "${s:-root-only}"
}
in_list() {
    local needle="$1"; shift
    local x
    for x in "$@"; do [ "$x" = "$needle" ] && return 0; done
    return 1
}

echo "=============================================================="
echo " Undeclared-state audit — $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "=============================================================="
echo
echo "--- /var/lib: state from services this config does NOT enable ---"
echo "    (safe to delete; it is not worth carrying into a persist list)"
orphan_total=0
for d in /var/lib/*; do
    n=$(basename "$d")
    if in_list "$n" "${SYSTEM_ORPHANED[@]}"; then
        printf '  %-8s %s\n' "$(size "$d")" "$n"
        orphan_total=$((orphan_total + 1))
    fi
done
[ "$orphan_total" -eq 0 ] && echo "  (none)"

echo
echo "--- /var/lib: NOT in the persist set and NOT known-orphaned ---"
echo "    (each of these is a decision you have not made yet)"
unknown=0
for d in /var/lib/*; do
    n=$(basename "$d")
    in_list "$n" "${SYSTEM_PERSIST[@]}" && continue
    in_list "$n" "${SYSTEM_ORPHANED[@]}" && continue
    printf '  %-8s %s\n' "$(size "$d")" "$n"
    unknown=$((unknown + 1))
done
[ "$unknown" -eq 0 ] && echo "  (none — the list above is complete)"

echo
echo "--- \$HOME: NOT declared and NOT marked disposable ---"
unknown_home=0
cd "$HOME" || exit 1
for d in .[!.]* *; do
    [ -e "$d" ] || continue
    in_list "$d" "${HOME_PERSIST[@]}" && continue
    in_list "$d" "${HOME_DISPOSABLE[@]}" && continue
    printf '  %-8s %s\n' "$(size "$d")" "$d"
    unknown_home=$((unknown_home + 1))
done
[ "$unknown_home" -eq 0 ] && echo "  (none)"

echo
echo "--- \$HOME: disposable (what root-on-tmpfs reclaims every boot) ---"
for d in "${HOME_DISPOSABLE[@]}"; do
    [ -e "$HOME/$d" ] && printf '  %-8s %s\n' "$(size "$HOME/$d")" "$d"
done

echo
echo "--------------------------------------------------------------"
echo "Reminder: /nix, /boot and /var/log are handled separately by the"
echo "impermanence module itself, not by this list."
echo
echo "Before adopting impermanence with only ONE disk, run:"
echo "  sudo ./scripts/recovery/backup-secure-boot-keys.sh <dir outside the repo>"
echo "A missed persist rule for /var/lib/sbctl is not recoverable from the boot menu."
