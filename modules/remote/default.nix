{ config, lib, pkgs, ... }:

let
  cfg = config.dimension.remote;
in
{
  options.dimension.remote = {
    enable = lib.mkEnableOption "Dimension native remote desktop foundation";

    sunshine = {
      enable = lib.mkEnableOption "Sunshine game streaming server (Moonlight protocol)";

      openFirewall = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Open Sunshine streaming ports in the firewall
          (TCP 47984 47989 48010; UDP 47998 47999 48000 48002).
        '';
      };

      autoStart = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Start Sunshine automatically at login for enabled users.";
      };
    };

    wol = {
      enable = lib.mkEnableOption "Wake-on-LAN support";

      interface = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = ''
          Network interface on which to enable WOL (e.g. "eth0").
          When empty, a one-shot systemd service applies WOL to all
          Ethernet interfaces at boot via ethtool.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      systemd.tmpfiles.rules = [
        "d /etc/dimension/remote 0755 root root -"
      ];
    }

    (lib.mkIf cfg.sunshine.enable {
      services.sunshine = {
        enable = true;
        autoStart = cfg.sunshine.autoStart;
        openFirewall = cfg.sunshine.openFirewall;
        capSysAdmin = false;
      };

      security.rtkit.enable = true;
    })

    (lib.mkIf (cfg.wol.enable && cfg.wol.interface != "") {
      networking.interfaces.${cfg.wol.interface}.wakeOnLan.enable = true;
    })

    (lib.mkIf (cfg.wol.enable && cfg.wol.interface == "") {
      systemd.services.dimension-wol = {
        description = "Enable Wake-on-LAN on all Ethernet interfaces";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writeShellScript "dimension-wol-all" ''
            set -eu
            for iface in /sys/class/net/*; do
              name="$(${pkgs.coreutils}/bin/basename "$iface")"
              if [ -d "$iface/device" ] && ${pkgs.gnugrep}/bin/grep -q '^1$' "$iface/carrier" 2>/dev/null; then
                ${pkgs.ethtool}/bin/ethtool -s "$name" wol g || true
              fi
            done
          '';
          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = true;
        };
      };
    })
  ]);
}
