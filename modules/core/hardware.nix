{ pkgs, ... }:
# Only what is true of BOTH machines. Anything vendor-specific belongs in
# machines/<machine>/, because a specialisation can add but never remove: a
# driver enabled here is enabled on the tower too, whether or not the hardware
# exists.
{
  hardware.graphics.enable = true;

  # enable32Bit is NOT set here. It exists for Steam, which is desktop-only, and
  # machines/desktop/default.nix sets it. It used to be `true` in this file as
  # well, which made the desktop's line a no-op and its "desktop-only" comment
  # false — the laptop was carrying the whole 32-bit graphics stack for nothing.

  # intel-media-driver / vpl-gpu-rt (VA-API) and intel-gpu-tools moved to
  # machines/laptop/graphics.nix. They were here, so the AMD/NVIDIA tower was
  # installing an Intel media driver and `intel_gpu_top`.
  #
  # libva-utils stays: `vainfo` is the verification tool for BOTH VA-API stacks
  # (iHD on the laptop, nvidia-vaapi-driver on the tower).
  environment.systemPackages = with pkgs; [ libva-utils ];

  # hardware.enableRedistributableFirmware is set once, in
  # hosts/portable/hardware-shared.nix, next to the microcode selection it
  # belongs with. It was defined in both files.
  #
  # boot.kernelModules and boot.extraModulePackages are not declared empty here
  # either — [] is already the default, and declaring it in two files made
  # "where is this set?" ambiguous. iwlwifi and i2c-dev are auto-loaded by udev
  # when the hardware is detected, so nothing needs eager loading; the tower's
  # ddcci-driver is added in machines/desktop/peripherals.nix.
}
