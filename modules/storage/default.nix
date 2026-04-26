{ config, lib, pkgs, ... }:

let
  cfg = config.dimension.storage;
in
{
  options.dimension.storage.enable = lib.mkEnableOption "Dimension unified storage foundation";

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d /etc/dimension/storage 0755 root root -"
      "d /mnt/dimension 0755 root root -"
    ];

    systemd.services.dimension-storage = {
      description = "Dimension storage placeholder";
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
