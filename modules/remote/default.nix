{ config, lib, pkgs, ... }:

let
  cfg = config.dimension.remote;
in
{
  options.dimension.remote.enable = lib.mkEnableOption "Dimension native remote desktop foundation";

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d /etc/dimension/remote 0755 root root -"
    ];

    systemd.services.dimension-remote = {
      description = "Dimension remote desktop placeholder";
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
