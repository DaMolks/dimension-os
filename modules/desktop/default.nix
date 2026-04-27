{ config, lib, pkgs, ... }:

let
  cfg = config.dimension.desktop;
  dimensionSddmTheme = pkgs.sddm-chili-theme.override {
    themeConfig = {
      Background = "${../../assets/wallpapers/dimension-default.svg}";
    };
  };
in
{
  options.dimension.desktop.enable = lib.mkEnableOption "Dimension desktop stack";

  config = lib.mkIf cfg.enable {
    services.xserver.enable = true;

    services.desktopManager.plasma6.enable = true;

    services.displayManager.sddm = {
      enable = true;
      theme = "chili";
      wayland.enable = true;
    };

    services.displayManager.defaultSession = "plasma";

    networking.networkmanager.enable = true;

    services.pipewire = {
      enable = true;
      pulse.enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
    };

    hardware.bluetooth.enable = true;

    environment.systemPackages = with pkgs; [
      firefox
      kdePackages.konsole
      kdePackages.dolphin
      kdePackages.ark
      kdePackages.spectacle
      dimensionSddmTheme
    ];
  };
}
