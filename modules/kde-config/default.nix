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

        [General]
        ColorScheme=Dimension

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

      "xdg/plasma-org.kde.plasma.desktop-appletsrc".text = ''
        [Containments][1]
        activityId=
        formfactor=2
        immutability=1
        lastScreen=0
        location=4
        plugin=org.kde.panel
        wallpaperplugin=org.kde.image

        [Containments][1][Applets][2]
        immutability=1
        plugin=org.kde.plasma.kickoff

        [Containments][1][Applets][2][Configuration][Shortcuts]
        global=Alt+F1

        [Containments][1][Applets][3]
        immutability=1
        plugin=org.kde.plasma.icontasks

        [Containments][1][Applets][3][Configuration][General]
        launchers=applications:dimension-search.desktop,applications:dimension-hub.desktop,applications:dimension-settings.desktop

        [Containments][1][Applets][4]
        immutability=1
        plugin=org.kde.plasma.systemtray

        [Containments][1][Applets][4][Configuration]
        SystrayContainmentId=5

        [Containments][1][Applets][6]
        immutability=1
        plugin=org.kde.plasma.digitalclock

        [Containments][1][General]
        AppletOrder=2;3;4;6

        [Containments][5]
        activityId=
        formfactor=2
        immutability=1
        lastScreen=0
        location=4
        plugin=org.kde.plasma.private.systemtray
        wallpaperplugin=org.kde.image

        [Containments][7]
        activityId=
        formfactor=0
        immutability=1
        lastScreen=0
        location=0
        plugin=org.kde.desktopcontainment
        wallpaperplugin=org.kde.image

        [Containments][7][Wallpaper][org.kde.image][General]
        FillMode=2
        Image=${../../assets/wallpapers/dimension-default.svg}
      '';
    };
  };
}
