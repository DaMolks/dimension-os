{ config, lib, pkgs, ... }:

let
  cfg = config.dimension.kde;
in
{
  options.dimension.kde.enable =
    lib.mkEnableOption "Dimension minimal KDE visual configuration";

  config = lib.mkIf cfg.enable {
    # Ensure these packages are present even if the theme module is disabled.
    environment.systemPackages = with pkgs; [
      papirus-icon-theme
      layan-cursors
    ];

    # System-wide KDE defaults written to /etc/xdg/.
    # KDE reads these as defaults; per-user settings in ~/.config/ take
    # precedence once changed in KDE System Settings.
    environment.etc = {
      "xdg/kdeglobals".text = ''
        [Icons]
        Theme=Papirus-Dark

        [KDE]
        LookAndFeelPackage=org.kde.breezedark.desktop
        SingleClick=false

        [Mouse]
        cursorTheme=layan-cursors
      '';

      # kcminputrc is the authoritative source for cursor settings in KDE.
      "xdg/kcminputrc".text = ''
        [Mouse]
        cursorTheme=layan-cursors
        cursorSize=24
      '';

      "xdg/baloofilerc".text = ''
        [Basic Settings]
        Indexing-Enabled=true

        [General]
        folders[$e]=$HOME,/mnt/dimension
        exclude folders[$e]=/proc,/sys,/dev,/nix,/run,/boot,/tmp
      '';
    };
  };
}
