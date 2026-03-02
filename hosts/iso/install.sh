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

# Select host
HOST=$(gum choose --header "Select host configuration:" "desktop" "p14s")
gum confirm "Use '$HOST' configuration?" || exit 1

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

# Generate hardware configuration
echo "Generating hardware configuration..."
nixos-generate-config --root /mnt
cp /mnt/etc/nixos/hardware-configuration.nix "hosts/$HOST/hardware-configuration.nix"

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
