# Dimension - Roadmap

## Phase 1 - Base générique

Statut : terminé

- flake.nix structuré
- hôte générique `main`
- module `base`
- configuration minimale évaluable
- support VM / machine neutre

---

## Phase 2 - Desktop minimal

Statut : terminé

- module `desktop`
- KDE Plasma Wayland
- SDDM
- NetworkManager
- PipeWire
- Bluetooth
- paquets graphiques de base

Non inclus à ce stade :
- thème Dimension / Layan
- dock custom
- Dimension Search
- widgets

---

## Phase 3 - Éditions et profils

Statut : terminé

- option `dimension.edition`
- éditions documentées :
  - desktop
  - laptop
  - server
  - server-headless
  - print-station
  - gaming
  - workstation
- activation des fondations par édition
- documentation `docs/EDITIONS.md`

---

## Phase 4 - Cadrage installateur

Statut : terminé

- documentation `docs/INSTALLER.md`
- parcours d’installation cadré
- choix édition depuis un ISO unique
- mode standalone prévu
- onboarding post-installation identifié

---

## Phase 5 - Fondations Dimension

Statut : terminé

- module `network` stub
- module `node` stub
- module `remote` stub
- module `hub` stub
- module `storage` stub

Ces modules posent la structure système sans implémenter les services réels.

---

## Phase 6 - Implémentation des premiers daemons réels

Statut : prochaine grande phase

Objectif :
- remplacer progressivement les stubs par des daemons minimaux réels
- conserver la modularité actuelle
- garder chaque service activable et testable séparément

Priorités envisagées :
- `dimension-node` minimal
- journalisation propre
- fichiers d’état structurés
- protocole local interne simple
- base de communication future avec le Hub

Hors périmètre initial :
- WireGuard
- pairing complet
- sync multi-machines
- stockage partagé réel
- streaming
- UI custom

---

## Phase 7 - Hub réel

Statut : à venir

- API minimale
- registre machines
- auth simple
- base persistante
- intégration avec Dimension Node

---

## Phase 8 - Réseau Dimension

Statut : à venir

- découverte locale
- pairing
- WireGuard
- intégration Hub

---

## Phase 9 - Stockage Dimension

Statut : à venir

- SMB
- SFTP
- montage automatique
- espace unifié `/mnt/dimension`

---

## Phase 10 - Bureau à distance natif

Statut : à venir

- intégration bureau à distance Dimension
- sessions distantes
- WOL configuré via onboarding
- intégration future streaming si nécessaire

---

## Phase 11 - Search, Shell et Widgets

Statut : à venir

- Dimension Search
- providers simples
- dock custom
- widgets
- shell complet

---

## Phase 12 - Éditions spécialisées

Statut : à venir

- gaming
- print-station
- workstation
- laptop avancé
- outils propres à chaque édition

---

## Phase 13 - Polissage

Statut : à venir

- thème Dimension
- login custom
- expérience installateur complète
- performances
- tests VM et machines réelles
