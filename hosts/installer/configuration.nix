{ inputs, lib, ... }:

{
  imports = [
    "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-plasma6.nix"
    ../../modules/base
    ../../modules/profiles
  ];

  dimension = {
    edition = "desktop";
    desktop.enable = lib.mkForce false;
    hub.enable = lib.mkForce false;
    node.enable = lib.mkForce false;
    remote.enable = lib.mkForce false;
    storage.enable = lib.mkForce false;
    wireguard.enable = lib.mkForce false;
  };

  networking.hostName = "dimension-installer";

  system.stateVersion = "24.05";
}
