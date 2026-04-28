{ config, lib, pkgs, ... }:

let
  cfg = config.dimension.homeTheatre;
  kodiEnabled = cfg.kiosk == "kodi" || cfg.kiosk == "both";
  steamEnabled = cfg.kiosk == "steam" || cfg.kiosk == "both";

  kodiSessionLauncher = pkgs.writeShellScriptBin "dimension-kodi-session" ''
    exec ${pkgs.kodi-wayland}/bin/kodi-standalone
  '';

  kodiDesktopEntry = pkgs.makeDesktopItem {
    name = "kodi";
    desktopName = "Kodi";
    comment = "Kodi media center";
    exec = "${kodiSessionLauncher}/bin/dimension-kodi-session";
    icon = "kodi";
    categories = [ "AudioVideo" "Video" "Player" ];
    terminal = false;
  };

  kodiSessionPackage =
    (pkgs.writeTextDir "share/wayland-sessions/kodi.desktop" ''
      [Desktop Entry]
      Name=Kodi
      Comment=Kodi media center session
      Exec=${kodiSessionLauncher}/bin/dimension-kodi-session
      Type=Application
    '').overrideAttrs (_: {
      passthru.providedSessions = [ "kodi" ];
    });
in
{
  options.dimension.homeTheatre = {
    enable = lib.mkEnableOption "Dimension TV and living-room experience";

    autoLogin = {
      enable = lib.mkEnableOption "auto-login for the home-theatre session";

      user = lib.mkOption {
        type = lib.types.str;
        default = "media";
        description = "User account to auto-login for the home-theatre session.";
      };
    };

    kiosk = lib.mkOption {
      type = lib.types.enum [ "kodi" "steam" "both" ];
      default = "kodi";
      description = "TV-first kiosk focus for the home-theatre edition.";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      assertions = [
        {
          assertion = !cfg.autoLogin.enable || cfg.autoLogin.user != "";
          message = "dimension.homeTheatre.autoLogin.user must be set when auto-login is enabled.";
        }
        {
          assertion = !cfg.autoLogin.enable || builtins.hasAttr cfg.autoLogin.user config.users.users;
          message = "dimension.homeTheatre.autoLogin.user must refer to an existing user when auto-login is enabled.";
        }
      ];

      dimension.kde.panel.enable = false;

      hardware.bluetooth.enable = true;
      hardware.bluetooth.powerOnBoot = true;

      services.blueman.enable = true;
      services.udev.packages = [ pkgs.game-devices-udev-rules ];

      environment.systemPackages = [
        pkgs.libcec
      ];

      # PipeWire is already enabled by the desktop module. HDMI audio routing
      # still depends on the target GPU/receiver hardware and EDID behavior.
      boot.plymouth.enable = true;
      boot.kernelParams = [
        "quiet"
        "splash"
      ];
    }

    (lib.mkIf kodiEnabled {
      environment.systemPackages = [
        pkgs.kodi-wayland
        kodiDesktopEntry
      ];

      services.displayManager.sessionPackages = [ kodiSessionPackage ];
    })

    (lib.mkIf steamEnabled {
      programs.steam.enable = true;
      programs.steam.gamescopeSession.enable = true;
    })

    (lib.mkIf cfg.autoLogin.enable {
      services.displayManager.autoLogin.enable = true;
      services.displayManager.autoLogin.user = cfg.autoLogin.user;

      services.displayManager.defaultSession =
        if cfg.kiosk == "kodi" then lib.mkForce "kodi"
        else if cfg.kiosk == "steam" then lib.mkForce "steam"
        else lib.mkDefault "plasma";
    })
  ]);
}
