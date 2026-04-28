{ config, lib, pkgs, ... }:

let
  cfg = config.dimension.apps;

  # Placeholder script : envoie une notification KDE via notify-send.
  # Le chemin de notify-send est absolu (store), aucune dépendance PATH.
  mkPlaceholder = name: summary: body:
    pkgs.writeShellScriptBin name ''
      exec ${pkgs.libnotify}/bin/notify-send \
        --app-name="Dimension" \
        ${lib.escapeShellArg summary} \
        ${lib.escapeShellArg body}
    '';

  dimensionSearch = pkgs.writeShellScriptBin "dimension-search" ''
    exec ${pkgs.kdePackages.krunner}/bin/krunner
  '';

  dimensionHub = mkPlaceholder "dimension-hub"
    "Dimension Hub"
    "Hub local disponible sur http://127.0.0.1:8787";

  dimensionIcons = pkgs.runCommand "dimension-icons" {} ''
    install -Dm0644 ${../../assets/icons/256/dimension-search.png} \
      $out/share/icons/hicolor/256x256/apps/dimension-search.png
    install -Dm0644 ${../../assets/icons/256/dimension-hub.png} \
      $out/share/icons/hicolor/256x256/apps/dimension-hub.png
    install -Dm0644 ${../../assets/icons/256/dimension-settings.png} \
      $out/share/icons/hicolor/256x256/apps/dimension-settings.png
  '';

  # .desktop installé dans share/applications/ via writeTextDir.
  # KDE le découvre automatiquement depuis XDG_DATA_DIRS.
  # Icon= référence les icônes installées dans hicolor par dimensionIcons.
  mkDesktop = { name, desktopName, comment, bin, icon, categories, keywords }:
    pkgs.writeTextDir "share/applications/${name}.desktop" ''
      [Desktop Entry]
      Version=1.1
      Type=Application
      Name=${desktopName}
      Comment=${comment}
      Exec=${bin}
      Icon=${icon}
      Categories=${categories};
      Keywords=${keywords};
      StartupNotify=false
      Terminal=false
    '';

in
{
  options.dimension.apps = {
    enable = lib.mkEnableOption "Dimension application entries (.desktop + scripts)";

    _settingsPackage = lib.mkOption {
      type = lib.types.package;
      internal = true;
      description = "The dimension-settings binary — placeholder until the settings module is enabled.";
      default = mkPlaceholder "dimension-settings"
        "Dimension Paramètres"
        "Configuration système — à venir.";
      defaultText = lib.literalExpression "dimension-settings placeholder";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      dimensionSearch
      dimensionHub
      cfg._settingsPackage
      dimensionIcons

      (mkDesktop {
        name       = "dimension-search";
        desktopName = "Dimension Search";
        comment    = "Recherche unifiée — applications, fichiers, commandes";
        bin        = "${dimensionSearch}/bin/dimension-search";
        icon       = "dimension-search";
        categories = "Utility";
        keywords   = "recherche;search;dimension";
      })

      (mkDesktop {
        name        = "dimension-hub";
        desktopName = "Dimension Hub";
        comment     = "Gestion des nœuds Dimension locaux";
        bin         = "${dimensionHub}/bin/dimension-hub";
        icon        = "dimension-hub";
        categories  = "Network;System";
        keywords    = "hub;node;dimension;réseau";
      })

      (mkDesktop {
        name        = "dimension-settings";
        desktopName = "Dimension Paramètres";
        comment     = "Configuration du système Dimension";
        bin         = "${cfg._settingsPackage}/bin/dimension-settings";
        icon        = "dimension-settings";
        categories  = "System;Settings";
        keywords    = "paramètres;settings;configuration;dimension";
      })
    ];
  };
}
