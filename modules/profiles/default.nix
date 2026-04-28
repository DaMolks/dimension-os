{ config, lib, pkgs, ... }:

let
  cfg = config.dimension;
in
{
  imports = [
    ../apps
    ../desktop
    ../hub
    ../kde-config
    ../network
    ../node
    ../remote
    ../storage
    ../theme
    ../wireguard
  ];

  options.dimension.edition = lib.mkOption {
    type = lib.types.enum [
      "desktop"
      "laptop"
      "server"
      "server-headless"
      "print-station"
      "gaming"
      "workstation"
    ];
    default = "server-headless";
    description = "Dimension edition to install on this machine.";
  };

  config = lib.mkMerge [
    {
      dimension = {
        apps.enable    = lib.mkDefault (cfg.edition != "server-headless");
        desktop.enable = lib.mkDefault (cfg.edition != "server-headless");
        hub.enable = lib.mkDefault (cfg.edition == "server");
        kde.enable = lib.mkDefault (cfg.edition != "server-headless");
        network.enable = lib.mkDefault true;
        network.avahi.enable = lib.mkDefault (cfg.edition != "server-headless");
        node.enable = lib.mkDefault true;
        remote.enable = lib.mkDefault true;
        storage.enable = lib.mkDefault true;
        theme.enable = lib.mkDefault (cfg.edition != "server-headless");
        wireguard.enable = lib.mkDefault false;
      };
    }

    (lib.mkIf (cfg.edition == "gaming") {
      hardware.opengl.enable = true;
      hardware.opengl.driSupport32Bit = true;
      programs.steam.enable = true;
      programs.gamemode.enable = true;

      dimension.remote.sunshine.enable = lib.mkDefault true;
    })

    (lib.mkIf (cfg.edition == "workstation") {
      environment.systemPackages = with pkgs; [
        libreoffice
        gimp
        inkscape
        vscode
      ];

      services.printing.enable = true;
    })

    (lib.mkIf (cfg.edition == "print-station") {
      services.printing = {
        enable = true;
        drivers = [ pkgs.gutenprint ];
      };

      dimension.storage.samba.enable = lib.mkDefault true;
    })

    (lib.mkIf (cfg.edition == "laptop") {
      services.tlp.enable = true;
      services.fprintd.enable = true;
      hardware.sensor.iio.enable = true;
    })
  ];
}
