{ config, lib, pkgs, ... }:

let
  cfg = config.dimension.storage;
in
{
  options.dimension.storage = {
    enable = lib.mkEnableOption "Dimension unified storage foundation";

    path = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/dimension";
      description = "Base path for Dimension shared storage.";
    };

    samba = {
      enable = lib.mkEnableOption "Samba (SMB) sharing of Dimension storage";

      workgroup = lib.mkOption {
        type = lib.types.str;
        default = "DIMENSION";
        description = "SMB workgroup name announced on the LAN.";
      };

      shareName = lib.mkOption {
        type = lib.types.str;
        default = "dimension";
        description = "SMB share name visible to clients.";
      };

      openFirewall = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Open SMB/NetBIOS ports (137-139 UDP, 445 TCP) in the firewall.";
      };
    };

    sftp = {
      enable = lib.mkEnableOption "SFTP access to Dimension storage via OpenSSH";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      systemd.tmpfiles.rules = [
        "d /etc/dimension/storage 0755 root root -"
        "d ${cfg.path} 0775 root users -"
      ];
    }

    (lib.mkIf cfg.samba.enable {
      services.samba = {
        enable = true;
        openFirewall = cfg.samba.openFirewall;
        settings = {
          global = {
            workgroup = cfg.samba.workgroup;
            "server string" = "Dimension Storage";
            "server role" = "standalone server";
            security = "user";
            "map to guest" = "Bad User";
            "dns proxy" = "no";
            "log level" = "1";
            "max log size" = "1000";
          };
          "${cfg.samba.shareName}" = {
            path = cfg.path;
            browseable = "yes";
            "read only" = "no";
            "guest ok" = "yes";
            "create mask" = "0664";
            "directory mask" = "0775";
            comment = "Dimension shared storage";
          };
        };
      };

      services.samba-wsdd = {
        enable = true;
        openFirewall = cfg.samba.openFirewall;
      };
    })

    (lib.mkIf cfg.sftp.enable {
      services.openssh = {
        enable = true;
        extraConfig = ''
          Subsystem sftp ${pkgs.openssh}/libexec/sftp-server
        '';
      };
    })
  ]);
}
