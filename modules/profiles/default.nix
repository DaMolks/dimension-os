{ config, lib, pkgs, ... }:

let
  cfg = config.dimension;
in
{
  imports = [
    ../apps
    ../desktop
    ../home-theatre
    ../hub
    ../kde-config
    ../network
    ../node
    ../remote
    ../sddm
    ../storage
    ../theme
    ../wireguard
  ];

  options.dimension.edition = lib.mkOption {
    type = lib.types.enum [
      "desktop"
      "laptop"
      "home-theatre"
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
        sddm.enable = lib.mkDefault (cfg.edition != "server-headless");
        storage.enable = lib.mkDefault true;
        theme.enable = lib.mkDefault (cfg.edition != "server-headless");
        wireguard.enable = lib.mkDefault false;
      };
    }

    (lib.mkIf (cfg.edition == "home-theatre") {
      dimension.homeTheatre.enable = true;
      dimension.apps.enable = false;
      dimension.desktop.enable = true;
      dimension.kde.enable = true;
    })

    (lib.mkIf (cfg.edition == "gaming") {
      hardware.opengl.enable = true;
      hardware.opengl.driSupport32Bit = true;
      hardware.xone.enable = true;
      powerManagement.cpuFreqGovernor = "performance";
      programs.steam.enable = true;
      programs.steam.gamescopeSession.enable = true;
      programs.gamemode.enable = true;
      services.udev.packages = [ pkgs.game-devices-udev-rules ];

      environment.systemPackages = with pkgs; [
        gamescope
        mangohud
      ];

      dimension.remote.sunshine.enable = lib.mkDefault true;
    })

    (lib.mkIf (cfg.edition == "workstation") {
      environment.systemPackages = with pkgs; [
        libreoffice
        gimp
        inkscape
        vscode
        git
        htop
        tmux
        neovim
        ripgrep
        fd
        jq
      ];

      fonts.packages = with pkgs; [
        jetbrains-mono
        nerd-fonts.jetbrains-mono
        nerd-fonts.symbols-only
      ];

      users.users.${config.dimension.mainUser}.extraGroups = lib.mkAfter [ "docker" ];

      virtualisation.docker.enable = true;
      services.flatpak.enable = true;
      services.printing.enable = true;
      xdg.portal.enable = true;
    })

    (lib.mkIf (cfg.edition == "print-station") {
      environment.systemPackages = with pkgs; [
        cups-filters
        ghostscript
      ];

      services.avahi.enable = true;
      services.avahi.nssmdns4 = true;
      services.printing = {
        enable = true;
        drivers = with pkgs; [
          gutenprint
          hplip
        ];
      };

      dimension.storage.samba.enable = lib.mkDefault true;
    })

    (lib.mkIf (cfg.edition == "laptop") {
      hardware.bluetooth.enable = true;
      hardware.bluetooth.powerOnBoot = true;
      services.fprintd.enable = true;
      services.auto-cpufreq.enable = true;
      services.geoclue2.enable = true;
      services.libinput.enable = true;
      services.libinput.touchpad.naturalScrolling = true;
      services.libinput.touchpad.tapping = true;
      services.localtimed.enable = true;
      services.power-profiles-daemon.enable = lib.mkForce false;
      services.thermald.enable = true;
      services.tlp.enable = lib.mkForce false;
      hardware.sensor.iio.enable = true;
    })
  ];
}
