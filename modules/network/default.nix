{ config, lib, pkgs, ... }:

let
  cfg = config.dimension.network;
in
{
  options.dimension.network.enable = lib.mkEnableOption "Dimension network foundation";

  config = lib.mkIf cfg.enable {
    networking.networkmanager.enable = true;

    systemd.tmpfiles.rules = [
      "d /etc/dimension 0755 root root -"
    ];

    systemd.services.dimension-network = {
      description = "Dimension network placeholder";
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.coreutils}/bin/true";
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        RestrictAddressFamilies = [ "AF_UNIX" ];
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        SystemCallArchitectures = "native";
      };
    };
  };
}
