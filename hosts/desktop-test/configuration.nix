{ lib, ... }:

{
  # Test host for validating the desktop edition without changing main.
  imports = [
    ../../modules/base
    ../../modules/profiles
  ];

  dimension.edition = "desktop";

  networking.hostName = "dimension-desktop-test";

  boot.loader.grub = {
    enable = true;
    device = lib.mkDefault "nodev";
  };

  fileSystems."/" = {
    device = lib.mkDefault "/dev/disk/by-label/nixos";
    fsType = lib.mkDefault "ext4";
  };

  system.stateVersion = "24.05";
}
