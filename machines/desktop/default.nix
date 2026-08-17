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

  # Bad-RAM reservations from MemTest86 (2026-05-13, 3 passes).
  # Coalesced bad-page clusters at ~15.1 GiB — single DIMM likely failing.
  # Total reserved: ~735 KiB across 8 ranges. Desktop-only: this is that
  # machine's RAM, and applying it on the laptop reserved addresses at random.
  # kernelParams is a list, so these append with no mkForce needed.
  boot.kernelParams = [
    "memmap=0x40000\$0x3c5e00000" # 256 KiB
    "memmap=0x5000\$0x3c623b000" # 20 KiB
    "memmap=0xd000\$0x3c6640000" # 52 KiB
    "memmap=0x3000\$0x3c675c000" # 12 KiB
    "memmap=0x2b000\$0x3c974b000" # 172 KiB
    "memmap=0x1000\$0x3cda04000" # 4 KiB
    "memmap=0x31000\$0x3cdb40000" # 196 KiB
    "memmap=0x5000\$0x3ce65b000" # 20 KiB
  ];

  # 32-bit graphics libraries are only needed for Steam, which is desktop-only.
  hardware.graphics.enable32Bit = true;
}
