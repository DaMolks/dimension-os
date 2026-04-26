# Dimension - Tasks

## Terminé

### Base

- [x] créer `flake.nix`
- [x] créer l’hôte générique `main`
- [x] créer le module `base`
- [x] configurer locale, utilisateur, Nix, firewall et outils de base
- [x] rendre `nix flake check` valide

### Desktop

- [x] créer le module `desktop`
- [x] ajouter `dimension.desktop.enable`
- [x] configurer KDE Plasma Wayland
- [x] configurer SDDM
- [x] configurer NetworkManager
- [x] configurer PipeWire
- [x] configurer Bluetooth
- [x] ajouter les paquets graphiques de base

### Éditions

- [x] créer le module `profiles`
- [x] ajouter `dimension.edition`
- [x] définir les éditions Dimension
- [x] activer le desktop selon l’édition
- [x] activer les fondations par édition
- [x] documenter les éditions dans `docs/EDITIONS.md`
- [x] aligner `SPEC.md` avec les éditions

### Installateur

- [x] cadrer le parcours d’installation
- [x] documenter l’ISO unique
- [x] documenter le choix d’édition
- [x] documenter standalone / Hub détecté
- [x] documenter l’onboarding post-installation

### Fondations stubs

- [x] créer le module `network`
- [x] créer le module `node`
- [x] créer le module `remote`
- [x] créer le module `hub`
- [x] créer le module `storage`
- [x] exporter les modules dans `flake.nix`
- [x] importer les modules dans `hosts/main/configuration.nix`
- [x] garder les services en placeholders sans logique réelle

---

## Prochaine grande phase - Implémentation des premiers daemons réels

### Dimension Node

- [ ] définir le périmètre du premier daemon réel
- [ ] choisir le runtime initial
- [ ] créer un binaire ou script minimal
- [ ] remplacer le placeholder `dimension-node`
- [ ] écrire un état minimal dans `/var/lib/dimension`
- [ ] journaliser proprement dans systemd
- [ ] conserver une option de désactivation propre

### Contrats internes

- [ ] définir les fichiers d’état locaux
- [ ] définir les chemins de configuration dans `/etc/dimension`
- [ ] définir les conventions de logs
- [ ] documenter les responsabilités de chaque daemon

### Validation

- [ ] vérifier `nix flake check`
- [ ] vérifier activation/désactivation par module
- [ ] tester `server-headless`
- [ ] tester une édition avec desktop

---

## À venir

### Hub

- [ ] remplacer le stub `dimension-hub`
- [ ] ajouter une API minimale
- [ ] ajouter un registre machines
- [ ] ajouter une base persistante
- [ ] ajouter une auth simple

### Network

- [ ] remplacer le stub `dimension-network`
- [ ] ajouter découverte locale
- [ ] ajouter pairing
- [ ] ajouter WireGuard
- [ ] intégrer le Hub

### Remote

- [ ] remplacer le stub `dimension-remote`
- [ ] définir le bureau à distance natif
- [ ] intégrer le comportement WOL via onboarding
- [ ] définir les sessions distantes

### Storage

- [ ] remplacer le stub `dimension-storage`
- [ ] configurer SMB
- [ ] configurer SFTP
- [ ] configurer montage automatique
- [ ] exposer l’espace unifié `/mnt/dimension`

### Search / Shell / Widgets

- [ ] configurer KRunner ou provider initial
- [ ] créer Dimension Search
- [ ] créer dock custom
- [ ] créer widgets
- [ ] créer shell complet

### UI

- [ ] créer app Tauri
- [ ] intégrer React
- [ ] créer thème Dimension
- [ ] créer paramètres Dimension

### Éditions spécialisées

- [ ] définir les logiciels `gaming`
- [ ] définir les logiciels `print-station`
- [ ] définir les logiciels `workstation`
- [ ] définir les réglages `laptop`

### Sécurité et finalisation

- [ ] gérer clés
- [ ] sécuriser API
- [ ] limiter accès
- [ ] tester VM
- [ ] tester réseau
- [ ] tester UX
