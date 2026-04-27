{ config, lib, ... }:

let
  cfg = config.dimension.wireguard;
in
{
  options.dimension.wireguard = {
    enable = lib.mkEnableOption "Dimension WireGuard VPN interface";

    privateKeyFile = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        Path to the WireGuard private key file for this machine.
        Must be created manually on the machine and never stored in Git.
        Expected permissions: 0600, owned by root.
      '';
    };

    address = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        IP address with prefix length assigned to this machine on the
        Dimension VPN subnet, for example "10.100.0.1/24".
      '';
    };

    listenPort = lib.mkOption {
      type = lib.types.port;
      default = 51820;
      description = "UDP port WireGuard listens on.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Open the WireGuard listen port in the NixOS firewall.
        Required for this machine to accept inbound WireGuard connections.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.privateKeyFile != "";
        message = "dimension.wireguard.privateKeyFile must be set when WireGuard is enabled.";
      }
      {
        assertion = cfg.address != "";
        message = "dimension.wireguard.address must be set when WireGuard is enabled.";
      }
    ];

    networking.wireguard.interfaces.dimension0 = {
      ips = [ cfg.address ];
      listenPort = cfg.listenPort;
      privateKeyFile = cfg.privateKeyFile;
      peers = [];
    };

    networking.firewall.allowedUDPPorts =
      lib.optional cfg.openFirewall cfg.listenPort;
  };
}
