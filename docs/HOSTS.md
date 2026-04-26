# Dimension - Hosts

Ce document decrit les hosts actuellement declares dans le flake.

Les hosts restent generiques : ils ne representent pas une machine physique
precise et ne doivent pas contenir de details materiels non portables.

---

## main

Fichier :
- `hosts/main/configuration.nix`

Role :
- host generique `server-headless`
- base de test local pour `dimension-hub` et `dimension-node`
- configuration minimale sans bureau graphique

Etat actuel :
- `dimension.edition = "server-headless"` via `lib.mkDefault`
- Hub active explicitement sur `127.0.0.1:8787`
- Node configure pour joindre le Hub local
- token de developpement lu depuis `/etc/dimension/secrets/hub-dev-token`

Limite :
- `main` ne sert pas au test UI
- KDE, le theme, les applications `.desktop` et les icones graphiques ne sont
  pas actives par defaut sur ce host

---

## desktop-test

Fichier :
- `hosts/desktop-test/configuration.nix`

Role :
- host desktop generique de validation visuelle
- cible de test pour KDE Plasma, la configuration KDE, le theme, les apps
  Dimension et les icones

Etat actuel :
- `dimension.edition = "desktop"`
- active les modules desktop via le profil d'edition
- active KDE, la base de theme, les entrees `.desktop` Dimension et les
  icones installees via le fallback `hicolor`

Limite :
- `desktop-test` reste un host de validation, pas une configuration materielle
  specifique
- il ne remplace pas `main` pour les tests Hub/Node locaux
