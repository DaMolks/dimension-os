{ lib, ... }:

{
  # Host-specific settings only. Shared configuration lives in modules/.
  # Keep this host limited to the base system for now.
  imports = [
    ../../modules/base
    ../../modules/hub
    ../../modules/network
    ../../modules/node
    ../../modules/profiles
    ../../modules/remote
    ../../modules/storage
  ];

  dimension.edition = lib.mkDefault "server-headless";

  networking.hostName = "dimension-main";

  boot.loader.grub = {
    enable = true;
    device = lib.mkDefault "nodev";
  };

  fileSystems."/" = {
    device = lib.mkDefault "/dev/disk/by-label/nixos";
    fsType = lib.mkDefault "ext4";
  };

  # Keep this in sync with the first NixOS release used on this machine.
  system.stateVersion = "24.05";
}
