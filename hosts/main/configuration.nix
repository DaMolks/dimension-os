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

  dimension.hub = {
    enable = true;
    host = "127.0.0.1";
    port = 8787;
  };

  dimension.node.hubUrl = "http://127.0.0.1:8787";

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
