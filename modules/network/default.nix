{ config, lib, ... }:

let
  cfg = config.dimension.network;
in
{
  options.dimension.network = {
    enable = lib.mkEnableOption "Dimension network foundation";

    avahi.enable = lib.mkEnableOption "Avahi-based mDNS support for Dimension LAN discovery";
  };

  config = lib.mkIf cfg.enable {
    networking.networkmanager.enable = true;
    networking.firewall.allowedUDPPorts = lib.optional cfg.avahi.enable 5353;

    systemd.tmpfiles.rules = [
      "d /etc/dimension 0755 root root -"
    ];

    services.avahi = lib.mkIf cfg.avahi.enable {
      enable = true;
      nssmdns4 = true;
      publish = {
        enable = true;
        userServices = true;
      };
    };
  };
}
