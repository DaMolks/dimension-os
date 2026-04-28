{ config, lib, pkgs, ... }:

let
  cfg = config.dimension.kde;
  edition = config.dimension.edition or "desktop";
  desktopEnabled = config.dimension.desktop.enable or false;
  isGaming = edition == "gaming";
  isHomeTheatre = edition == "home-theatre";
  favoriteLaunchers =
    [
      "dimension-search.desktop"
      "systemsettings.desktop"
      "org.kde.dolphin.desktop"
      "org.kde.konsole.desktop"
    ]
    ++ lib.optional desktopEnabled "firefox.desktop";
  kickoffFavorites = builtins.concatStringsSep ";" favoriteLaunchers;
  taskManagerLaunchers = builtins.concatStringsSep "," (map (launcher: "applications:${launcher}") favoriteLaunchers);
  quickLaunchDesktopFile = "file://${mangoHudToggle}/share/applications/dimension-mangohud-toggle.desktop";
  systrayAppletId = if isGaming then 7 else 6;
  clockAppletId = if isGaming then 8 else 7;
  showDesktopAppletId = if isGaming then 9 else 8;
  panelVisibility =
    if isGaming then 1
    else if isHomeTheatre then 2
    else 0;
  mangoHudToggle = pkgs.symlinkJoin {
    name = "dimension-mangohud-toggle";
    paths = [
      (pkgs.writeShellScriptBin "dimension-mangohud-toggle" ''
        set -eu

        config_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/MangoHud"
        config_file="$config_dir/MangoHud.conf"
        tmp_file="$(${pkgs.coreutils}/bin/mktemp)"

        cleanup() {
          ${pkgs.coreutils}/bin/rm -f "$tmp_file"
        }

        trap cleanup EXIT

        ${pkgs.coreutils}/bin/mkdir -p "$config_dir"

        if [ -f "$config_file" ] && ${pkgs.gnugrep}/bin/grep -Eq '^[[:space:]]*no_display([[:space:]]*=.*)?$' "$config_file"; then
          ${pkgs.gnused}/bin/sed '/^[[:space:]]*no_display([[:space:]]*=.*)?$/d' "$config_file" > "$tmp_file"
        else
          if [ -f "$config_file" ]; then
            ${pkgs.coreutils}/bin/cp "$config_file" "$tmp_file"
          fi
          printf '%s\n' 'no_display' >> "$tmp_file"
        fi

        ${pkgs.coreutils}/bin/mv "$tmp_file" "$config_file"
      '')
      (pkgs.writeTextDir "share/applications/dimension-mangohud-toggle.desktop" ''
        [Desktop Entry]
        Type=Application
        Version=1.0
        Name=MangoHud Toggle
        Comment=Toggle MangoHud default visibility for future launches
        Exec=dimension-mangohud-toggle
        Icon=applications-games
        Categories=Game;Utility;
        Terminal=false
      '')
    ];
  };
  plasmaPanelConfig = pkgs.writeText "dimension-plasma-org.kde.plasma.desktop-appletsrc" ''
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
    plugin=org.kde.plasma.panelspacer

    [Containments][1][Applets][3][Configuration][General]
    expanding=true

    [Containments][1][Applets][4]
    immutability=1
    plugin=org.kde.plasma.icontasks

    [Containments][1][Applets][4][Configuration][General]
    launchers=${taskManagerLaunchers}

    [Containments][1][Applets][5]
    immutability=1
    plugin=org.kde.plasma.panelspacer

    [Containments][1][Applets][5][Configuration][General]
    expanding=true

    ${lib.optionalString isGaming ''
    [Containments][1][Applets][6]
    immutability=1
    plugin=org.kde.plasma.quicklaunch

    [Containments][1][Applets][6][Configuration][General]
    launcherUrls=${quickLaunchDesktopFile}
    showLauncherNames=false
    ''}
    [Containments][1][Applets][${toString systrayAppletId}]
    immutability=1
    plugin=org.kde.plasma.systemtray

    [Containments][1][Applets][${toString systrayAppletId}][Configuration]
    SystrayContainmentId=20

    [Containments][1][Applets][${toString clockAppletId}]
    immutability=1
    plugin=org.kde.plasma.digitalclock

    [Containments][1][Applets][${toString showDesktopAppletId}]
    immutability=1
    plugin=org.kde.plasma.showdesktop

    [Containments][1][General]
    AppletOrder=2;3;4;5${lib.optionalString isGaming ";6"};${toString systrayAppletId};${toString clockAppletId};${toString showDesktopAppletId}

    [Containments][20]
    activityId=
    formfactor=2
    immutability=1
    lastScreen=0
    location=4
    plugin=org.kde.plasma.private.systemtray
    wallpaperplugin=org.kde.image

    [Containments][30]
    activityId=
    formfactor=0
    immutability=1
    lastScreen=0
    location=0
    plugin=org.kde.desktopcontainment
    wallpaperplugin=org.kde.image

    [Containments][30][Wallpaper][org.kde.image][General]
    FillMode=2
    Image=${../../assets/wallpapers/dimension-default.svg}
  '';
  plasmaShellConfig = pkgs.writeText "dimension-plasmashellrc" ''
    [PlasmaViews][Panel 1]
    panelVisibility=${toString panelVisibility}

    [PlasmaViews][Panel 1][Defaults]
    floating=1
    thickness=48
  '';
  kickoffFavoritesConfig = pkgs.writeText "dimension-kicker-extra-favoritesrc" ''
    [General]
    Prepend=${kickoffFavorites}
    IgnoreDefaults=true
  '';
in
{
  options.dimension.kde = {
    enable =
      lib.mkEnableOption "Dimension minimal KDE visual configuration";

    panel.enable =
      lib.mkEnableOption "Dimension default Plasma 6 panel seed for new users";
  };

  config = lib.mkIf cfg.enable {
    dimension.kde.panel.enable = lib.mkDefault true;

    # Ensure these packages are present even if the theme module is disabled.
    environment.systemPackages =
      (with pkgs; [
        papirus-icon-theme
        layan-cursors
      ])
      ++ lib.optionals (cfg.panel.enable && isGaming) [
        pkgs.kdePackages.kdeplasma-addons
        pkgs.mangohud
        mangoHudToggle
      ];

    # System-wide KDE defaults written to /etc/xdg/.
    # KDE reads these as defaults; per-user settings in ~/.config/ take
    # precedence once changed in KDE System Settings.
    environment.etc =
      {
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
      }
      // lib.optionalAttrs cfg.panel.enable {
        "skel/.config/plasma-org.kde.plasma.desktop-appletsrc" = {
          source = plasmaPanelConfig;
          mode = "444";
        };

        "skel/.config/plasmashellrc" = {
          source = plasmaShellConfig;
          mode = "444";
        };

        "xdg/kicker-extra-favoritesrc" = {
          source = kickoffFavoritesConfig;
          mode = "444";
        };
      };
  };
}
