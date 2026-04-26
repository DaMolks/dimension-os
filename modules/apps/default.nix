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

  dimensionSearch = mkPlaceholder "dimension-search"
    "Dimension Search"
    "Fonctionnalité à venir.";

  dimensionHub = mkPlaceholder "dimension-hub"
    "Dimension Hub"
    "Hub local disponible sur http://127.0.0.1:8787";

  dimensionSettings = mkPlaceholder "dimension-settings"
    "Dimension Paramètres"
    "Configuration système — à venir.";

  # .desktop installé dans share/applications/ via writeTextDir.
  # KDE le découvre automatiquement depuis XDG_DATA_DIRS.
  # Icon= référence un thème futur ; KDE affiche l'icône système par défaut
  # si le thème n'est pas encore présent.
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
  options.dimension.apps.enable =
    lib.mkEnableOption "Dimension application entries (.desktop + placeholder scripts)";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      dimensionSearch
      dimensionHub
      dimensionSettings

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
        bin         = "${dimensionSettings}/bin/dimension-settings";
        icon        = "dimension-settings";
        categories  = "System;Settings";
        keywords    = "paramètres;settings;configuration;dimension";
      })
    ];
  };
}
