# Dimension OS — Phase 2 : Bureau Apple-like Glass/Blur

> **For agentic workers:** Use superpowers:subagent-driven-development or superpowers:executing-plans task-by-task.

**Goal:** Bureau KDE Plasma 6 avec esthétique glassmorphism/blur, style Apple — zéro splash KDE, panel flottant vitré, fenêtres transparentes, thème cohérent de l'écran de login au bureau.

**Architecture:** Modules NixOS déclaratifs + plasma-manager (Home Manager) pour la config KDE reproductible. Kvantum pour le theming Qt transparent. Assets générés par Codex (wallpapers, icônes SVG).

**Tech Stack:** KDE Plasma 6, Kvantum, Klassy/Lightly, plasma-manager, Home Manager, KWin scripts, Nix

---

## Task 0 — Fix SDDM : afficher les vrais utilisateurs

**Fichiers :** `modules/base/default.nix`

### Prompt Codex

```
Dépôt : dimension-os
Fichier : modules/base/default.nix

Dans la déclaration users.users.${cfg.mainUser}, supprimer le champ description
("Dimension main user"). SDDM lit le champ GECOS de /etc/passwd comme nom
d'affichage — sans description, il affiche le username réel.

Changer :
  users.users.${cfg.mainUser} = {
    isNormalUser = true;
    description = "Dimension main user";
    extraGroups = [ "wheel" ];
  };

En :
  users.users.${cfg.mainUser} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

nix flake check --no-build doit passer.
```

---

## Task 1 — Recherche références et ajout plasma-manager au flake

**Fichiers :** `flake.nix`

### Prompt Codex

```
Dépôt : dimension-os
Objectif : recherche de projets similaires + ajout plasma-manager au flake.

PARTIE A — Recherche web (effectuer avant de coder)
Chercher et analyser les dépôts GitHub/GitLab suivants pour s'en inspirer :
- "plasma-manager" nixos home-manager kde configuration declarative
- "glassmorphism kde plasma" theme kvantum
- "macos-like kde nixos" dotfiles
- "lightly-blur" OR "klassy" kde window decoration
- Projets notables à inspecter :
  * pjones/plato ou tout nixos-config avec plasma-manager
  * Sekoia9/benix ou similar "beautiful nixos kde"
  * Search GitHub: topic:nixos topic:kde-plasma stars:>50
  * Kvantum themes avec transparence : "Utterly-Sweet", "Lavanda", "Marble"
  * KWin scripts blur : rechercher "kwin script blur force"
  * SDDM glassmorphism themes sur GitHub/GitLab/store.kde.org
Noter dans un commentaire en tête de chaque fichier créé les inspirations retenues.

PARTIE B — Ajout plasma-manager
Dans flake.nix, ajouter :
  home-manager.url = "github:nix-community/home-manager";
  home-manager.inputs.nixpkgs.follows = "nixpkgs";
  plasma-manager.url = "github:nix-community/plasma-manager";
  plasma-manager.inputs.nixpkgs.follows = "nixpkgs";
  plasma-manager.inputs.home-manager.follows = "home-manager";

Passer home-manager et plasma-manager dans specialArgs de mkNixosConfiguration.
Ajouter home-manager.nixosModules.home-manager comme module global optionnel
(les hosts l'activent via home-manager.users.${cfg.mainUser} = { ... }).

nix flake check --no-build doit passer.
```

---

## Task 2 — Assets visuels : wallpaper, icônes, splash

**Fichiers :**
- Créer : `assets/wallpapers/dimension-desktop-dark.png` (2560x1440 minimum)
- Créer : `assets/wallpapers/dimension-sddm-glass.png`
- Créer : `assets/icons/dimension-logo.svg`

### Prompt Codex

```
Dépôt : dimension-os
Objectif : générer les assets visuels Dimension OS.

Identité visuelle :
- Palette : fond #000F1F (bleu marine très sombre), accent #0078D7 (bleu vif),
  texte #E8F0F8 (blanc cassé froid)
- Style : glassmorphism, minimaliste, Apple-like, dark mode profond
- Pas de dégradés criards, pas de couleurs saturées sauf l'accent bleu

Assets à générer :

1. assets/wallpapers/dimension-desktop-dark.png (2560x1440)
   Wallpaper bureau principal :
   - Fond très sombre #000F1F avec légère texture noise subtile
   - Formes géométriques abstractes translucides (cercles, hexagones) en bleu très foncé
   - Effet de profondeur, style "deep space" ou "liquid glass"
   - Aucun texte, aucun logo

2. assets/wallpapers/dimension-sddm-glass.png (1920x1080)
   Wallpaper écran de login :
   - Similaire au wallpaper bureau mais plus épuré
   - Légère vignette sur les bords
   - Zone centrale dégagée pour le formulaire de login

3. assets/icons/dimension-logo.svg
   Logo vectoriel Dimension :
   - Lettre D stylisée ou forme géométrique abstraite évoquant une dimension/cube
   - Couleur unique #0078D7 sur fond transparent
   - Utilisable comme icône 256x256 et comme logo

4. assets/wallpapers/dimension-boot-splash-v2.png (1920x1080)
   Remplacement du splash Plymouth actuel :
   - Fond #000F1F pur
   - Logo Dimension centré, petit, élégant
   - Aucun texte

Utiliser les capacités de génération d'image de Codex ou des outils SVG/canvas
disponibles. Si génération programmatique : Python avec Pillow ou Cairo,
ou Node avec canvas. Committer les fichiers générés.
```

---

## Task 3 — Thème Kvantum glassmorphism

**Fichiers :**
- Créer : `modules/theme/kvantum/DimensionGlass.kvconfig`
- Créer : `modules/theme/kvantum/DimensionGlass.svg`
- Modifier : `modules/theme/default.nix`

### Prompt Codex

```
Dépôt : dimension-os
Objectif : créer un thème Kvantum glassmorphism pour Dimension OS.

Kvantum est un moteur de thème Qt qui permet transparence et blur sur les
fenêtres d'applications (Dolphin, Konsole, etc.).

RECHERCHE PRÉALABLE :
Inspecter sur GitHub les thèmes Kvantum suivants pour comprendre la syntaxe :
- "Utterly-Sweet" kvantum (https://github.com/EliverLara/Utterly-Sweet)
- "Marble" kvantum (disponible dans nixpkgs : pkgs.marble-shell-theme ou similaire)
- "Nordic" kvantum
Comprendre les champs : translucency, blurring, reduce_window_opacity,
window_opacity, reduce_menu_opacity, menu_opacity.

CRÉER modules/theme/kvantum/DimensionGlass.kvconfig :
Thème Kvantum avec :
- window_opacity = 85 (15% transparent)
- reduce_window_opacity = 10
- blurring = true
- translucency = true
- reduce_menu_opacity = 20
- menu_shadow_depth = 6
- tooltip_shadow_depth = 4
- Couleurs cohérentes avec la palette Dimension (#000F1F, #0078D7, #E8F0F8)
- Inspired by the "Utterly-Sweet-transparent" or "Nordic" translucent variants

CRÉER modules/theme/kvantum/DimensionGlass.svg :
SVG minimaliste Kvantum (éléments de base : frame, button states).
S'inspirer d'un thème existant simple.

MODIFIER modules/theme/default.nix :
- Packager le thème Kvantum via pkgs.stdenvNoCC.mkDerivation :
  installe DimensionGlass.kvconfig et DimensionGlass.svg dans
  $out/share/Kvantum/DimensionGlass/
- Ajouter pkgs.libsForQt5.qtstyleplugin-kvantum (ou kdePackages.qtstyleplugin-kvantum)
  aux packages système
- Écrire /etc/xdg/Kvantum/kvantum.kvconfig via environment.etc :
  [General]
  theme=DimensionGlass
- Écrire /etc/xdg/kdeglobals : ajouter/modifier
  [KDE]
  widgetStyle=kvantum

nix flake check --no-build doit passer.
```

---

## Task 4 — Décoration de fenêtres : Klassy avec blur

**Fichiers :**
- Modifier : `modules/theme/default.nix`
- Modifier : `modules/kde-config/default.nix`

### Prompt Codex

```
Dépôt : dimension-os
Objectif : configurer Klassy comme décorateur de fenêtres KDE avec bordures
translucides et intégration glassmorphism.

RECHERCHE PRÉALABLE :
- Inspecter le repo GitHub "paulmcauley/klassy" pour comprendre les options
  de configuration disponibles
- Chercher "klassy kwinrc configuration" pour voir les clés de config
- Chercher des nixos configs qui utilisent Klassy via plasma-manager

PARTIE A — Ajouter Klassy aux packages
Dans modules/theme/default.nix, ajouter pkgs.kdePackages.klassy (si disponible
dans nixpkgs-unstable) ou pkgs.klassy aux packages système.
Si non disponible dans nixpkgs, créer un package custom via fetchFromGitHub +
cmake build dans modules/theme/klassy-package.nix.

PARTIE B — Configurer via /etc/xdg/kwinrc
Dans modules/kde-config/default.nix, dans environment.etc, ajouter
"xdg/kwinrc".text avec :
  [org.kde.kdecoration2]
  library=com.github.paulmcauley.klassy
  theme=Klassy

  [Compositing]
  OpenGLIsUnsafe=false
  
  [Effect-Blur]
  BlurStrength=8
  NoiseStrength=2

  [Plugins]
  blurEnabled=true
  contrastEnabled=true

PARTIE C — KWin blur sur le panel et les fenêtres
S'assurer que les effets blur et contrast sont activés.
Dans kwinrc :
  [Effect-overview]
  BorderActivate=9
Chercher comment forcer le blur sur toutes les fenêtres via kwinrc ou
un KWin script et l'appliquer.

nix flake check --no-build doit passer.
```

---

## Task 5 — Panel flottant glassmorphism via plasma-manager

**Fichiers :**
- Créer : `modules/kde-config/plasma-home.nix`
- Modifier : `modules/kde-config/default.nix`

### Prompt Codex

```
Dépôt : dimension-os
Objectif : remplacer la config panel via /etc/skel/ par plasma-manager
(Home Manager) pour une config KDE déclarative qui s'applique immédiatement
à l'utilisateur, pas seulement aux nouveaux users.

RECHERCHE PRÉALABLE :
- Lire la doc plasma-manager : https://github.com/nix-community/plasma-manager
- Chercher des exemples de config panel plasma-manager sur GitHub
- Inspecter les options : programs.plasma.panels, programs.plasma.kwin,
  programs.plasma.configFile

CRÉER modules/kde-config/plasma-home.nix :
Module NixOS qui configure home-manager pour l'utilisateur principal
avec plasma-manager. Ce module doit :

1. Être conditionnel sur config.dimension.kde.enable
2. Utiliser :
   home-manager.users.${config.dimension.mainUser} = { pkgs, ... }: {
     imports = [ inputs.plasma-manager.homeManagerModules.plasma-manager ];
     
     programs.plasma = {
       enable = true;
       
       # Panel flottant centré en bas, style macOS
       panels = [{
         location = "bottom";
         floating = true;
         height = 48;
         widgets = [
           { kickoff = { icon = "start-here-kde"; }; }
           { iconTasks = {
               launchers = [
                 "applications:dimension-search.desktop"
                 "applications:org.kde.dolphin.desktop"
                 "applications:org.kde.konsole.desktop"
                 "applications:firefox.desktop"
               ];
             };
           }
           "org.kde.plasma.panelspacer"
           "org.kde.plasma.systemtray"
           { digitalClock = { date = { format = "shortDate"; }; }; }
           "org.kde.plasma.showdesktop"
         ];
       }];
       
       # Wallpaper
       workspace = {
         wallpaper = toString ../../assets/wallpapers/dimension-desktop-dark.png;
         colorScheme = "Dimension";
         lookAndFeel = "org.kde.breezedark.desktop";
         iconTheme = "Papirus-Dark";
         cursorTheme = "layan-cursors";
       };
       
       # KWin
       kwin = {
         effects = {
           blur.enable = true;
           desktopSwitching.animation = "slide";
           windowOpenClose.animation = "slide";
         };
         titlebarButtons = {
           left = [];
           right = [ "minimize" "maximize" "close" ];
         };
       };
       
       # Supprimer le splash KDE
       configFile = {
         "ksplashrc" = {
           "KSplash" = {
             "Engine" = "none";
             "Theme" = "none";
           };
         };
       };
     };
   };

3. Supprimer l'ancienne config panel via /etc/skel/ dans modules/kde-config/default.nix
   (les blocs environment.etc."skel/.config/plasma-org.kde.plasma.desktop-appletsrc"
   et "skel/.config/plasmashellrc") car plasma-manager les remplace.

MODIFIER modules/kde-config/default.nix :
- Ajouter import de ./plasma-home.nix
- Supprimer les entrées skel qui sont remplacées

nix flake check --no-build doit passer.
```

---

## Task 6 — SDDM glassmorphism complet

**Fichiers :**
- Modifier : `modules/sddm/default.nix`

### Prompt Codex

```
Dépôt : dimension-os
Objectif : améliorer le thème SDDM Dimension avec un vrai glassmorphism.
Le thème QML actuel existe dans modules/sddm/default.nix.

RECHERCHE PRÉALABLE :
- Chercher sur GitHub "sddm theme glassmorphism qml"
- Inspecter : "sddm-sugar-candy", "sddm-astronaut-theme", "maldives-theme"
- Comprendre les effets blur QML disponibles : FastBlur, GaussianBlur, Qt5Compat

AMÉLIORATIONS à apporter au QML existant :

1. Background avec blur réel sur la vidéo/image de fond :
   Utiliser MultiEffect (Qt6) ou GaussianBlur (Qt5Compat) sur l'image de fond
   visible derrière la carte de login. Remplacer le FastBlur actuel qui ne
   s'applique qu'à la source de la carte.

2. Carte de login améliorée :
   - Bordure avec gradient subtil bleu → transparent
   - Ombre portée douce (layer + shadow effect)
   - Champ username et password avec icônes (user-identity, dialog-password)
   - Animation de scale au focus des champs (scale: activeFocus ? 1.02 : 1.0)
   - Bouton login avec animation de pulse sur hover

3. Sélecteur de session (bouton discret en bas à droite) :
   - Afficher les sessions disponibles (Wayland, X11)
   - Style cohérent avec la carte

4. Utiliser le wallpaper assets/wallpapers/dimension-sddm-glass.png généré en Task 2

5. Animations fluides :
   - Fade in de la carte au démarrage (opacity: 0 → 1, duration: 400ms)
   - Ease de connexion réussie

Réécrire le mainQml dans modules/sddm/default.nix avec ces améliorations.
Garder la même structure pkgs.stdenvNoCC.mkDerivation pour le themePackage.

nix flake check --no-build doit passer.
```

---

## Task 7 — Suppression splash KDE + polish final

**Fichiers :**
- Modifier : `modules/kde-config/default.nix`
- Modifier : `modules/plymouth/default.nix`

### Prompt Codex

```
Dépôt : dimension-os
Objectif : supprimer tout splash/logo KDE non Dimension + polish final.

1. SUPPRIMER LE SPLASH KDE (ksplash) :
   Dans modules/kde-config/default.nix, dans environment.etc, ajouter :
   "xdg/ksplashrc".text = ''
     [KSplash]
     Engine=none
     Theme=none
   '';
   (Si plasma-manager est utilisé depuis Task 5, vérifier que ce n'est pas en conflit.)

2. SUPPRIMER LA SPLASH PLASMA DE DÉMARRAGE :
   Dans kdeglobals via environment.etc."xdg/kdeglobals", ajouter :
   [KDE]
   ...existing...
   splashScreen=none

3. ANIMATION DE DÉMARRAGE KWIN :
   Dans kwinrc via environment.etc, s'assurer que :
   [Effect-Login]
   Login effect = none (ou désactivé)

4. PLYMOUTH V2 :
   Si assets/wallpapers/dimension-boot-splash-v2.png existe (Task 2),
   mettre à jour modules/plymouth/default.nix pour utiliser ce nouveau splash.
   Sinon, vérifier que l'existant est propre.

5. FONTS :
   Ajouter dans modules/theme/default.nix ou modules/base/default.nix :
   fonts.packages = with pkgs; [ inter noto-fonts noto-fonts-cjk ];
   Dans environment.etc."xdg/kdeglobals", section [General] :
   font=Inter,11,-1,5,50,0,0,0,0,0
   fixed=JetBrains Mono,10,-1,5,50,0,0,0,0,0
   smallestReadableFont=Inter,8,-1,5,50,0,0,0,0,0
   toolBarFont=Inter,10,-1,5,50,0,0,0,0,0
   menuFont=Inter,10,-1,5,50,0,0,0,0,0

6. KONSOLE PROFILE GLASS :
   Créer un profil Konsole transparent via environment.etc :
   "xdg/konsolerc".text avec un profil "Dimension" :
   fond #000F1F, opacité 85%, police JetBrains Mono 11

nix flake check --no-build doit passer.
```

---

## Task 8 — Test VM Phase 2

**Manuelle.**

```
Reconstruire l'ISO :
  nix build .#nixosConfigurations.installer.config.system.build.isoImage

Installer dans une VM fraîche (ou rebuilder un système existant depuis Phase 1) :
  Sur le système Phase 1 installé :
  nixos-rebuild switch --flake /etc/dimension#<hostname>

Checklist visuelle :
  [ ] SDDM : fond glass, carte glassmorphism, animation fade-in
  [ ] SDDM : username réel affiché (pas "dimension main user")
  [ ] Boot : aucun logo KDE, aucun splash Breeze
  [ ] Bureau : wallpaper sombre Dimension
  [ ] Panel : flottant, semi-transparent/vitré, centré
  [ ] Fenêtres : légère transparence + blur en arrière-plan
  [ ] Konsole : fond semi-transparent
  [ ] Dolphin : apparence Kvantum glassmorphism
  [ ] Boutons fenêtres : style Klassy (ou similaire), droite uniquement
  [ ] Fonts : Inter lisible partout
  [ ] Icônes : Papirus-Dark cohérent
  [ ] Curseur : layan-cursors

Screenshots à garder pour référence avant Phase 3.
```

---

## Ordre d'exécution

```
Task 0 → Task 1 → Task 2 (assets) → Task 3 → Task 4 → Task 5 → Task 6 → Task 7 → Task 8
```

Tasks 2, 3, 4 peuvent tourner en parallèle après Task 1.

---

## Phase 3 (après validation Phase 2)

Hub/Node production, WireGuard auto-apply, pairing UI.
