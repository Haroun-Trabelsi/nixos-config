{ pkgs, ... }:
# AMD tower with an RTX 5060 Ti. Reached by selecting the `desktop` entry in the
# boot menu; it is a NixOS specialisation of the laptop base, so everything here
# is ADDITIVE. Anything that needs to be absent on the laptop must simply never
# be set in the base.
{
  imports = [
    ./nvidia.nix
    ./peripherals.nix
    ./steam.nix
    ./tv-audio.nix
  ];

  # Flips machines/laptop off (it is inherited from the parent config) and lets
  # home-manager modules branch via osConfig.machine.profile.
  machine.profile = "desktop";

  # Makes the boot entry visibly distinct from the base generation, so the two
  # UKIs per generation are tellable apart in the menu.
  system.nixos.tags = [ "desktop" ];

  environment.systemPackages = with pkgs; [ nvtopPackages.nvidia ];

  services = {
    power-profiles-daemon.enable = false;

    upower = {
      enable = true;
      percentageLow = 20;
      percentageCritical = 5;
      percentageAction = 3;
      criticalPowerAction = "PowerOff";
    };
  };

  # A desktop is on mains permanently; latency is worth more than watts here.
  powerManagement.cpuFreqGovernor = "performance";

  # The bad-RAM `memmap=` reservations are GONE. They coalesced bad-page clusters
  # found by MemTest86 on 2026-05-13 at ~15.1 GiB — ~735 KiB across 8 ranges on
  # a single failing DIMM. That DIMM has been replaced.
  #
  # They had to go rather than being left as harmless: a memmap reservation is
  # an ABSOLUTE physical address range. Against different silicon those
  # addresses are not the old defects, they are eight arbitrary holes punched in
  # working memory. Keeping them would have been carrying a dead stick's defect
  # map onto a healthy one.
  #
  # If RAM is ever suspected again: run MemTest86, then
  # scripts/scripts/badmem-from-memtest86.py to turn its logs back into a
  # kernelParams list. Nothing else here depends on them.

  # 32-bit graphics libraries are only needed for Steam, which is desktop-only.
  hardware.graphics.enable32Bit = true;
}
