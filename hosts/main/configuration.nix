{ lib, ... }:

{
  # Host-specific settings only. Shared configuration lives in modules/.
  # Keep this host limited to the base system for now.
  imports = [
    ../../modules/apps
    ../../modules/base
    ../../modules/hub
    ../../modules/kde-config
    ../../modules/network
    ../../modules/node
    ../../modules/profiles
    ../../modules/remote
    ../../modules/storage
    ../../modules/theme
  ];

  dimension.edition = lib.mkDefault "server-headless";

  dimension.hub = {
    enable = true;
    host = "127.0.0.1";
    port = 8787;
    # Token file must be created manually on the machine — never stored in Git.
    # See docs/RUNTIME.md and docs/SECURITY.md for setup instructions.
    devTokenFile = "/etc/dimension/secrets/hub-dev-token";
  };

  dimension.node = {
    hubUrl = "http://127.0.0.1:8787";
    # Same token file shared with the Hub via the dimension-secrets group.
    hubTokenFile = "/etc/dimension/secrets/hub-dev-token";
  };

  # WireGuard is intentionally disabled here until the Dimension VPN
  # subnet and peer application flow are defined.
  #
  # dimension.wireguard = {
  #   enable = true;
  #   privateKeyFile = "/etc/dimension/secrets/wg-private-key";
  #   address = "10.100.0.X/24";
  #   openFirewall = true;
  # };

  # Shared group allowing both dimension-hub and dimension-node to read secrets.
  users.groups.dimension-secrets = {};
  users.users.dimension-hub.extraGroups = [ "dimension-secrets" ];
  users.users.dimension-node.extraGroups = [ "dimension-secrets" ];

  # Restricted directory for local secrets — contents are never in Git.
  systemd.tmpfiles.rules = [
    "d /etc/dimension/secrets 0750 root dimension-secrets -"
  ];

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
