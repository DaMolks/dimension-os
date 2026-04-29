# Dimension OS — Phase 1 : Installateur CLI

> **For agentic workers:** Use superpowers:subagent-driven-development or superpowers:executing-plans to implement task-by-task.

**Goal:** ISO Dimension minimal (pas de live OS, zéro texte NixOS visible) qui installe un système Dimension complet via un installateur CLI interactif.

**Architecture:** ISO NixOS minimal → auto-login → installateur CLI whiptail → disko partitionne → nixos-install --flake embarqué. Le flake auto-découvre les hosts via `builtins.readDir ./hosts` pour ne pas avoir à l'éditer à chaque nouvelle machine.

**Tech Stack:** NixOS flakes, disko, whiptail, bash, GRUB, Plymouth

---

## Task 1 — Flake : auto-découverte hosts + input disko

**Fichiers :**
- Modifier : `flake.nix`

### Prompt Codex

```
Dépôt : dimension-os (NixOS flake)
Fichier cible : flake.nix

Contexte actuel : le flake déclare les hosts manuellement dans un attrset `hosts`
et les mappe via `lib.mapAttrs`. Il faut faire deux changements :

1. Ajouter disko comme input :
   disko.url = "github:nix-community/disko";
   disko.inputs.nixpkgs.follows = "nixpkgs";

2. Remplacer la déclaration manuelle des hosts par une auto-découverte :
   - Lire tous les sous-dossiers de ./hosts/ avec builtins.readDir
   - Pour chaque dossier qui contient un configuration.nix, créer une nixosConfiguration
   - Chaque host utilise system = "x86_64-linux" et modules = [ ./hosts/<nom>/configuration.nix ]
   - Passer disko.nixosModules.disko dans les specialArgs ou les modules disponibles
     (l'inclure comme module optionnel global pour que les hosts puissent l'utiliser)

Résultat attendu : `nix flake check --no-build` passe toujours.
Les trois hosts existants (main, desktop-test, installer) doivent continuer à évaluer.
```

---

## Task 2 — ISO minimal : remplacer Calamares par auto-login CLI

**Fichiers :**
- Modifier : `hosts/installer/configuration.nix`

### Prompt Codex

```
Dépôt : dimension-os
Fichier cible : hosts/installer/configuration.nix

Contexte actuel : l'installateur importe
  "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-plasma6.nix"
ce qui produit un live OS KDE complet avec Calamares. On veut le remplacer par un
ISO minimal CLI.

Changements :
1. Remplacer l'import Calamares par :
   "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"

2. Garder les imports Dimension existants (modules/base, modules/profiles) mais
   désactiver tout ce qui n'est pas utile dans un ISO installer :
   - dimension.desktop.enable = false (déjà)
   - dimension.kde.enable = false (mkForce)
   - dimension.apps.enable = false (mkForce)
   - dimension.sddm.enable = false (mkForce)
   - dimension.theme.enable = false (mkForce)
   Garder : dimension.plymouth.enable = true, dimension.network.enable = true

3. Configurer l'auto-login sur tty1 :
   services.getty.autologinUser = "root";

4. Lancer automatiquement l'installateur au login root :
   Écrire un fichier /root/.bashrc (via environment.etc ou users.users.root.packages)
   qui exécute dimension-install au démarrage du shell si on est sur tty1 :
     [ "$(tty)" = "/dev/tty1" ] && exec dimension-install

5. Ajouter whiptail aux packages système de l'ISO :
   environment.systemPackages = with pkgs; [ whiptail parted util-linux ];

6. Embarquer le flake Dimension dans l'ISO pour que nixos-install puisse l'utiliser :
   environment.etc."dimension/flake".source = ../../.;
   (Cela rend le flake disponible à /etc/dimension/ sur l'ISO live)

7. Supprimer isoImage.grubTheme et isoImage.efiSplashImage du host installer
   (on les gère dans le module installer dédié — Task 5).

Résultat : `nix flake check --no-build` passe. L'ISO construit sans Calamares.
```

---

## Task 3 — Module disko : layout de partition simple GPT/EFI/ext4

**Fichiers :**
- Créer : `modules/installer/disko-simple.nix`

### Prompt Codex

```
Dépôt : dimension-os
Créer : modules/installer/disko-simple.nix

Ce module NixOS définit un layout disko paramétrable pour l'installation simple.
Il doit être importé par le host installé (pas par l'ISO lui-même).

Options à exposer sous dimension.installer.disk :
  - device (string, requis) : chemin du disque ex: "/dev/sda"
  - swapSize (string, défaut: "0") : taille swap, "0" = pas de swap
  - encrypt (bool, défaut: false) : réservé pour plus tard, toujours false pour l'instant

Configuration disko produite quand encrypt = false :
  - Partition 1 : ESP 512M, vfat, mountpoint = /boot
  - Partition 2 : reste du disque, ext4, mountpoint = /
  - Si swapSize != "0" : partition swap avant la root

Le module doit :
1. Déclarer les options sous options.dimension.installer.disk
2. Dans config = lib.mkIf (cfg.device != "") { ... } :
   - Configurer disko.devices.disk.main avec le device et les partitions ci-dessus
   - Ajouter boot.loader.systemd-boot.enable = true
   - Ajouter boot.loader.efi.canTouchEfiVariables = true
   - Ajouter fileSystems."/" et fileSystems."/boot" correspondant au layout

Suivre la syntaxe disko documentée sur github.com/nix-community/disko.
Le module ne fait rien si dimension.installer.disk.device = "" (défaut).

Résultat : le module s'évalue sans erreur avec `nix eval`.
```

---

## Task 4 — Script installateur CLI interactif

**Fichiers :**
- Modifier : `modules/base/default.nix` (remplacer le dimension-install actuel)

### Prompt Codex

```
Dépôt : dimension-os
Fichier cible : modules/base/default.nix

Le module base contient actuellement un script dimension-install minimal (génère
juste un configuration.nix). Il faut le remplacer par un installateur complet.

Le nouveau script dimension-install doit :

ÉTAPE 1 — Bienvenue
  - Effacer l'écran, afficher un header ASCII "Dimension OS" centré
  - whiptail --msgbox "Bienvenue dans l'installateur Dimension OS" 10 60

ÉTAPE 2 — Sélection du disque
  - Lister les disques disponibles avec :
    lsblk -d -o NAME,SIZE,MODEL --noheadings | grep -v loop
  - whiptail --menu pour sélectionner le disque (ex: /dev/sda)
  - Confirmer : "Tout le contenu de /dev/<disque> sera effacé. Confirmer ?"

ÉTAPE 3 — Édition
  - whiptail --menu avec les choix : desktop, laptop, gaming, workstation,
    print-station, home-theatre, server, server-headless

ÉTAPE 4 — Informations machine
  - Hostname (whiptail --inputbox, défaut: "dimension")
  - Nom d'utilisateur principal (défaut: "dimension")
  - Mot de passe (whiptail --passwordbox, confirmation)

ÉTAPE 5 — Résumé
  - whiptail --yesno affichant : disque, édition, hostname, utilisateur
  - Si non : reprendre depuis ÉTAPE 2

ÉTAPE 6 — Partitionnement avec disko-install
  - disko-install combine le partitionnement ET nixos-install en une commande :
    disko-install --flake /etc/dimension#$HOSTNAME --disk main $DISK
  - Pour que ça fonctionne offline, le binaire disko doit être dans les packages ISO :
    environment.systemPackages = [ pkgs.disko ] dans hosts/installer/configuration.nix
  - disko-install lit la config disko depuis le module dimension.installer.disk
    du host $HOSTNAME dans le flake embarqué à /etc/dimension/
  - Si disko-install n'est pas disponible dans la version utilisée, fallback :
    Générer dynamiquement un fichier /tmp/disko-$HOSTNAME.nix avec le device
    substitué, puis : nix run .#disko -- --mode disko /tmp/disko-$HOSTNAME.nix
  - Dans les deux cas, SUPPRIMER l'ÉTAPE 9 (nixos-install séparé) car
    disko-install l'inclut.

ÉTAPE 7 — Génération hardware-configuration
  - nixos-generate-config --root /mnt --no-filesystems
  - (--no-filesystems car disko gère déjà les filesystems)

ÉTAPE 8 — Génération configuration host
  - Créer /mnt/etc/dimension/ avec une copie du flake depuis /etc/dimension/
  - Créer /mnt/etc/dimension/hosts/$HOSTNAME/configuration.nix :

{ lib, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/base
    ../../modules/profiles
    ../../modules/installer/disko-simple.nix
  ];

  dimension.edition = "$EDITION";
  dimension.mainUser = "$USERNAME";
  dimension.installer.disk.device = "$DISK";

  networking.hostName = "$HOSTNAME";

  system.stateVersion = "24.05";
}

  - Copier /mnt/etc/nixos/hardware-configuration.nix vers
    /mnt/etc/dimension/hosts/$HOSTNAME/hardware-configuration.nix

ÉTAPE 9 — Installation
  - nixos-install --root /mnt --flake /mnt/etc/dimension#$HOSTNAME --no-root-passwd
  - Afficher la progression

ÉTAPE 10 — Mot de passe utilisateur
  - arch-chroot /mnt passwd $USERNAME (via nixos-enter)

ÉTAPE 11 — Fin
  - whiptail --msgbox "Installation terminée. Retirer le support et redémarrer."
  - Proposer reboot immédiat

Gestion d'erreurs : chaque étape critique (disko, nixos-install) doit vérifier
le code de retour. En cas d'échec, afficher l'erreur via whiptail et quitter proprement.

Le script est un pkgs.writeShellScriptBin "dimension-install" dans modules/base/default.nix.
Remplacer entièrement le script dimension-install existant.
Les dépendances nécessaires (whiptail, parted, nixos-install, disko) doivent être
disponibles — elles seront dans l'ISO via les packages système.

Résultat : le script s'évalue (nix flake check --no-build passe).
```

---

## Task 5 — Branding complet : zéro texte NixOS visible

**Fichiers :**
- Modifier : `hosts/installer/configuration.nix`
- Modifier : `modules/plymouth/default.nix` (vérification)
- Modifier : `modules/base/default.nix` (motd)

### Prompt Codex

```
Dépôt : dimension-os
Objectif : supprimer tout texte "NixOS" visible de l'ISO installateur.
Points à traiter :

1. GRUB — déjà partiellement brandé dans hosts/installer/configuration.nix.
   Vérifier que le titre du menu GRUB ne contient pas "NixOS".
   Dans isoImage.grubTheme, le theme.txt a title-text: "" (ok).
   S'assurer que les entrées du menu GRUB utilisent "Dimension OS" :
     boot.loader.grub.extraEntries ou via isoImage settings.
   Ajouter dans hosts/installer/configuration.nix :
     isoImage.isoName = "dimension-os-installer.iso";
     isoImage.volumeID = "DIMENSION_INSTALLER";

2. TTY / Console — supprimer le message de login NixOS :
   Dans hosts/installer/configuration.nix ajouter :
     users.motd = "";  (ou environment.motd si disponible)
     services.getty.helpLine = "";
     boot.kernelParams = [ "quiet" "loglevel=0" ];
     boot.initrd.verbose = false;
   Créer /etc/issue via environment.etc."issue".text = "" (fichier vide).

3. Plymouth — le module dimension.plymouth.enable = true est déjà configuré.
   Vérifier que boot.plymouth.enable = true est actif sur l'ISO.
   S'assurer que les kernelParams "quiet" et "splash" sont présents.

4. Splash KDE — N/A (pas de KDE dans l'ISO minimal).

5. Hostname du live ISO — déjà "dimension-installer" dans le host config. OK.

6. Shell prompt root — dans hosts/installer/configuration.nix, personnaliser le
   prompt bash root pour afficher "dimension-installer" au lieu d'un prompt par défaut :
     environment.interactiveShellInit = ''
       PS1='\[\e[1;34m\]Dimension\[\e[0m\] \w # '
       clear
     '';
   (Ce PS1 s'affiche brièvement avant que dimension-install prenne la main.)

7. Message ASCII au démarrage — créer un fichier /etc/dimension-banner via
   environment.etc."dimension-banner".text contenant un art ASCII "Dimension OS".
   L'appeler depuis le .bashrc root avant de lancer dimension-install.

Résultat : nix flake check --no-build passe.
À la construction, grep dans le résultat pour "NixOS" dans les fichiers texte
visibles (grub.cfg, issue, motd) doit retourner zéro occurrence.
```

---

## Task 6 — Test ISO VirtualBox

**Cette task est manuelle — aucun code à écrire.**

### Checklist de validation

```
Depuis WSL2 :
  cd /mnt/e/Projets/dimension-os
  nix build .#nixosConfigurations.installer.config.system.build.isoImage

L'ISO se trouve dans result/iso/*.iso.

Créer une VM VirtualBox :
  - Type : Linux / Other Linux (64-bit)
  - RAM : 2048 Mo minimum
  - Disque : 20 Go, VDI
  - Réseau : NAT
  - Activer EFI dans les paramètres système

Démarrer sur l'ISO et vérifier :
  [ ] Splash Plymouth Dimension visible au boot (pas de texte NixOS)
  [ ] GRUB titre "Dimension" ou aucun texte NixOS
  [ ] Auto-login root → banner ASCII Dimension → dimension-install se lance
  [ ] Étape sélection disque : /dev/sda visible
  [ ] Étape édition : les 8 éditions listées
  [ ] Étape hostname/user : saisie fonctionnelle
  [ ] Partitionnement disko : /dev/sda partitionné sans erreur
  [ ] nixos-install se termine sans erreur
  [ ] Reboot → le système installé démarre
  [ ] Le système installé : KDE Plasma démarre (si édition desktop)
  [ ] Le thème SDDM Dimension est présent sur le système installé
  [ ] Aucun texte "NixOS" visible à l'écran de login

Si un test échoue : noter l'étape et le message d'erreur exact.
```

---

## Ordre d'exécution recommandé

```
Task 1 → Task 2 → Task 3 → Task 4 → Task 5 → nix flake check → Task 6
```

Chaque task doit passer `nix flake check --no-build` avant de passer à la suivante.
Les tasks 1-3 sont des fondations, les tasks 4-5 sont les plus complexes.

---

## Phase 2 (après validation Phase 1)

Bureau Apple-like glass/blur — plan séparé à créer après validation ISO Phase 1 en VM.
Thèmes à rechercher : KDE Latte Dock alternatives, KWin blur scripts, glassmorphism
KDE, projets dotfiles "macOS-like NixOS", plasma-manager.
