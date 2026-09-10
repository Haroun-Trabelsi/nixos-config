#!/usr/bin/env bash
set -euo pipefail

WORK_DIR="/tmp/nixos-config"

echo "=== NixOS Installer ==="
echo

# Copy config to writable location
echo "Preparing configuration..."
rm -rf "$WORK_DIR"
cp -r /etc/nixos-config "$WORK_DIR"
chmod -R u+w "$WORK_DIR"
cd "$WORK_DIR"
git init --quiet && git add -A && git commit -m "init" --quiet

# Get username
USERNAME=$(gum input --header "Enter your username:" --placeholder "fantasy")
if ! [[ $USERNAME =~ ^[a-z][a-z0-9_-]{0,31}$ ]]; then
  echo "Invalid username: '$USERNAME'"
  exit 1
fi
gum confirm "Use '$USERNAME' as username?" || exit 1

# There is exactly ONE system configuration: hosts/portable. Both machines boot
# it — the AMD tower is a `specialisation` inside it, picked from the boot menu,
# not a separate host. The old "desktop"/"p14s" choice here referred to a
# hosts/<name>/ layout that no longer exists.
HOST="portable"
echo "Installing the single portable configuration (laptop base + desktop"
echo "specialisation). The machine is chosen at boot, not here."

# Show disk layout
echo
lsblk -o NAME,SIZE,TYPE,FSTYPE
echo
echo "Target disk (from hosts/$HOST/disko.nix):"
grep 'device' "hosts/$HOST/disko.nix" || true
echo

# Confirm destructive operation
gum style --foreground 196 --bold "WARNING: This will ERASE the target disk!"
gum confirm "Proceed with partitioning?" || exit 1

# Update username
sed -i "s/username = \"[^\"]*\"/username = \"${USERNAME}\"/" flake.nix

# Partition disk with disko
echo "Partitioning disk..."
disko --mode destroy,format,mount "hosts/$HOST/disko.nix"

# Hardware configuration.
#
# This used to `cp` the generated file to hosts/$HOST/hardware-configuration.nix
# and carry on. NOTHING imports that path: the mounts live in
# hosts/portable/hardware-shared.nix with UUIDs hardcoded for the ORIGINAL disk.
# So the install "succeeded" and then booted a config pointing at filesystems
# that do not exist on the new disk.
#
# disko has just formatted and mounted the target, so the real UUIDs are
# knowable now. Rewrite them into hardware-shared.nix rather than leaving a
# generated file nothing reads.
echo "Generating hardware configuration..."
nixos-generate-config --root /mnt --no-filesystems

HW="hosts/$HOST/hardware-shared.nix"
root_uuid=$(findmnt -no UUID /mnt)
boot_uuid=$(findmnt -no UUID /mnt/boot)
swap_uuid=$(lsblk -no UUID,FSTYPE | awk '$2 == "swap" { print $1; exit }')

for pair in "root:$root_uuid" "boot:$boot_uuid" "swap:$swap_uuid"; do
  if [ -z "${pair#*:}" ]; then
    echo "FAILED to discover the ${pair%%:*} UUID. Refusing to install a config"
    echo "that would point at the wrong filesystem. Fix $HW by hand."
    exit 1
  fi
done

echo "  root: $root_uuid"
echo "  boot: $boot_uuid"
echo "  swap: $swap_uuid"

# Each UUID appears exactly once in that file, on its own device/UUID line.
sed -i \
  -e "0,/by-uuid/{s|/dev/disk/by-uuid/[0-9a-fA-F-]*|/dev/disk/by-uuid/$root_uuid|}" \
  "$HW"
sed -i \
  -e "/fileSystems.\"\/boot\"/,/};/{s|/dev/disk/by-uuid/[0-9A-Fa-f-]*|/dev/disk/by-uuid/$boot_uuid|}" \
  -e "/swapDevices/,/];/{s|/dev/disk/by-uuid/[0-9a-fA-F-]*|/dev/disk/by-uuid/$swap_uuid|}" \
  "$HW"

echo "Rewrote the mount UUIDs in $HW:"
grep -n "by-uuid" "$HW"
gum confirm "Do those three UUIDs look right?" || exit 1

# Stage all changes so the flake can see them
git add -A
git commit -m "Install: update hardware-configuration and username" --quiet

# Install NixOS
echo "Installing NixOS..."
nixos-install --flake ".#$HOST" --no-root-password

# Copy config to user home on installed system
echo "Copying configuration to new system..."
TARGET_HOME="/mnt/home/$USERNAME"
mkdir -p "$TARGET_HOME/nixos-config"
cp -r "$WORK_DIR"/. "$TARGET_HOME/nixos-config/"
# Set ownership (UID 1000 = first normal user)
chown -R 1000:100 "$TARGET_HOME/nixos-config"

echo
gum style --foreground 76 --bold "Installation complete!"
echo "Your config is at /home/$USERNAME/nixos-config"
echo "Reboot to start using your new system."
