{ config, lib, ... }:

let
  cfg = config.dimension;
in
{
  imports = [
    ../desktop
    ../hub
    ../kde-config
    ../network
    ../node
    ../remote
    ../storage
    ../theme
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

  config.dimension = {
    desktop.enable = lib.mkDefault (cfg.edition != "server-headless");
    hub.enable = lib.mkDefault (cfg.edition == "server");
    kde.enable = lib.mkDefault (cfg.edition != "server-headless");
    network.enable = lib.mkDefault true;
    node.enable = lib.mkDefault true;
    remote.enable = lib.mkDefault true;
    storage.enable = lib.mkDefault true;
    theme.enable = lib.mkDefault (cfg.edition != "server-headless");
  };
}
