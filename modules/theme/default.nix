{ config, lib, pkgs, ... }:

let
  cfg = config.dimension.theme;
in
{
  options.dimension.theme.enable =
    lib.mkEnableOption "Dimension visual theme foundations";

  config = lib.mkIf cfg.enable {
    # Packages made available system-wide for KDE theme selection.
    # No user configuration is forced here — theme activation is done
    # via KDE System Settings or future Dimension tooling.
    #
    # layan-kde is not packaged in nixpkgs; layan-cursors is the available
    # Layan-family package. A full KDE colour scheme will be added later.
    environment.systemPackages = with pkgs; [
      papirus-icon-theme
      layan-cursors
      kdePackages.qtstyleplugin-kvantum
    ];
  };
}
