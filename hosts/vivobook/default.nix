{ ... }:
# The ASUS Vivobook's OWN install, on its internal NVMe — the disk that used to
# hold Windows.
#
# This is NOT the portable SSD. hosts/portable is one disk that boots two
# machines, with the AMD tower as a specialisation inside it. This host is a
# single machine with a single profile, so:
#
#   * NO ./../portable/specialisations.nix. Building the desktop specialisation
#     here would drag nvidia-x11 (885 MiB), nvidia-vaapi-driver and Steam's
#     32-bit stack into a laptop closure for a GPU that is not present, and add
#     a boot entry that cannot work. The laptop's own closure is ~31 GiB; there
#     is no reason to carry the tower's too.
#   * its own hostname, because it is a separate machine on the same tailnet.
#   * its own hardware file, because the root is an internal NVMe rather than a
#     USB-attached enclosure.
#
# Everything else — modules/core and machines/laptop — is shared with the
# portable disk, so the session, power tuning and Intel VA-API setup are
# identical to what the Vivobook already runs.
{
  imports = [
    ./hardware.nix
    ./../../modules/core
    ./../../machines/laptop
  ];

  # machine.profile already defaults to "laptop"; stated explicitly because this
  # host has no specialisation to make the default meaningful by contrast.
  machine.profile = "laptop";

  networking.hostName = "vivobook";

  # Distinguishes the boot entries from any generation left over from a portable
  # install, if both disks are ever attached.
  system.nixos.tags = [ "vivobook" ];
}
