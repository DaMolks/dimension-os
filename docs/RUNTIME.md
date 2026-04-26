# Dimension - Runtime

Ce document fixe les conventions runtime de Dimension.
Il sert de reference pour eviter que les modules systeme divergent dans leurs
chemins, noms de services et responsabilites.

Etat actuel :
- `dimension-node` est un agent minimal reel
- `dimension-hub` est un agent minimal reel
- `dimension-network`, `dimension-remote` et `dimension-storage` restent des placeholders
- aucune API, decouverte reseau, authentification, sync ou couche VPN n'est implementee

---

## Chemins

### /etc/dimension

Racine de configuration locale Dimension.

Existe actuellement :
- creee par le module `network` quand `dimension.network.enable = true`

Usage prevu :
- configuration commune locale
- points d'entree pour les sous-systemes Dimension

Pas encore implemente :
- schema de configuration
- fichiers de configuration communs
- secrets

### /var/lib/dimension

Racine d'etat local Dimension.

Existe actuellement :
- utilisee comme racine logique pour les donnees locales

Usage prevu :
- etat local persistant de la machine
- donnees gerees par les agents Dimension

Pas encore implemente :
- schema d'etat global
- synchronisation
- registre local complet

### /var/lib/dimension/node

Etat persistant de `dimension-node`.

Existe actuellement :
- cree par le module `node`
- contient `agent.sh`
- contient `id`, cree au premier demarrage si absent

Usage prevu :
- identite locale de la machine
- etat interne de l'agent local
- base future pour pairing, sync et relation Hub

Pas encore implemente :
- pairing
- connexion Hub
- sync machines
- protocole reseau

### /var/log/dimension

Logs locaux des composants Dimension generaux.

Existe actuellement :
- cree par le module `node`
- contient `node.log`

Usage prevu :
- logs lisibles hors journald pour les agents locaux
- complement aux logs systemd

Pas encore implemente :
- rotation specifique Dimension
- structure de logs normalisee

### /var/lib/dimension-hub

Etat persistant du Hub Dimension.

Existe actuellement :
- cree par le module `hub`
- contient `hub.sh`
- contient `id`, cree au premier demarrage si absent

Usage prevu :
- etat interne du serveur central Dimension
- future base de registre machines
- future base de donnees Hub

Pas encore implemente :
- SQLite
- registre machines
- comptes
- pairing

### /var/log/dimension-hub

Logs du Hub Dimension.

Existe actuellement :
- cree par le module `hub`
- contient `hub.log`

Usage prevu :
- logs lisibles du Hub
- complement aux logs systemd

Pas encore implemente :
- rotation specifique Hub
- format structure

### /etc/dimension/hub

Configuration du Hub Dimension.

Existe actuellement :
- cree par le module `hub`

Usage prevu :
- configuration future du Hub
- parametres locaux du serveur central

Pas encore implemente :
- fichier de configuration
- auth
- certificats
- secrets

---

## Services

### dimension-node

Statut : agent minimal reel

Module :
- `modules/node/default.nix`

Activation :
- option `dimension.node.enable`
- active par defaut via les editions Dimension

Comportement actuel :
- service `Type=simple`
- tourne en tant que `root`
- demarre `/var/lib/dimension/node/agent.sh`
- redemarre avec `Restart=always`
- cree un ID local si absent
- ecrit dans `/var/log/dimension/node.log`
- log vers stdout, donc journald
- ecrit un timestamp periodique

Pas encore implemente :
- API
- WebSocket
- connexion Hub
- pairing
- sync
- WireGuard

### dimension-hub

Statut : agent minimal reel

Module :
- `modules/hub/default.nix`

Activation :
- option `dimension.hub.enable`
- active seulement pour l'edition `server` pour l'instant

Comportement actuel :
- service `Type=simple`
- tourne en tant que `root`
- demarre `/var/lib/dimension-hub/hub.sh`
- redemarre avec `Restart=always`
- cree un ID Hub si absent
- ecrit dans `/var/log/dimension-hub/hub.log`
- log vers stdout, donc journald
- ecrit un timestamp periodique

Pas encore implemente :
- API HTTP
- SQLite
- auth
- pairing
- WireGuard
- Web UI

### dimension-network

Statut : placeholder

Module :
- `modules/network/default.nix`

Activation :
- option `dimension.network.enable`
- active par defaut via les editions Dimension

Comportement actuel :
- active NetworkManager
- cree `/etc/dimension`
- service `oneshot`
- execute seulement `true`

Pas encore implemente :
- decouverte reseau
- mDNS
- WireGuard
- pairing
- integration Hub

### dimension-remote

Statut : placeholder

Module :
- `modules/remote/default.nix`

Activation :
- option `dimension.remote.enable`
- active par defaut via les editions Dimension

Comportement actuel :
- cree `/etc/dimension/remote`
- service `oneshot`
- execute seulement `true`

Pas encore implemente :
- bureau a distance reel
- Sunshine
- Moonlight
- session streaming
- WOL
- integration login manager

### dimension-storage

Statut : placeholder

Module :
- `modules/storage/default.nix`

Activation :
- option `dimension.storage.enable`
- active par defaut via les editions Dimension

Comportement actuel :
- cree `/etc/dimension/storage`
- cree `/mnt/dimension`
- service `oneshot`
- execute seulement `true`

Pas encore implemente :
- SMB
- SFTP
- montage automatique
- partage `/home`
- decouverte des machines

---

## Regles de contribution runtime

- Les chemins persistants vont dans `/var/lib/dimension*`.
- Les logs texte vont dans `/var/log/dimension*` et doivent aussi partir vers journald quand un service tourne.
- La configuration declarative locale va dans `/etc/dimension`.
- Les services systemd doivent rester des modules Nix separes.
- Les services reels doivent rester minimaux tant que leurs contrats ne sont pas documentes.
- Aucun service ne doit ajouter API, reseau, stockage ou auth sans phase explicite.
