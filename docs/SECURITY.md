# Dimension - Securite

Ce document pose les principes de securite avant toute exposition de
`dimension-hub`, `dimension-node` ou des services associes au LAN ou a WireGuard.

Il ne decrit pas une implementation complete. Il sert de garde-fou pour les
prochaines phases.

---

## Principes

### LAN et WireGuard uniquement

Dimension doit rester limite au reseau local et au VPN WireGuard.
Aucun composant Dimension ne doit etre expose directement sur Internet.

### Aucun service public Internet

Les services Dimension ne doivent pas ouvrir de port public par defaut.
Toute exposition externe doit etre refusee tant qu'elle n'est pas explicitement
documentee, securisee et testee.

### Bind local par defaut

Les services en developpement doivent ecouter sur `127.0.0.1` par defaut.
Un bind LAN ou WireGuard doit etre un choix explicite, documente et valide.

### Firewall strict

Le firewall doit rester ferme par defaut.
Chaque port ouvert doit avoir :
- un objectif clair
- un protocole documente
- une portee reseau definie
- une validation de securite

### Secrets jamais en clair dans Git

Aucun secret ne doit etre versionne :
- mots de passe
- tokens
- cles privees
- cles WireGuard
- secrets de pairing
- certificats prives

Les secrets devront etre geres par un mecanisme dedie avant toute fonctionnalite
qui en depend.

### Permissions minimales

Chaque service doit avoir uniquement les permissions necessaires.
Les chemins runtime doivent etre limites et documentes.

### Root seulement si necessaire

Les premiers services tournent en `root` pour simplifier la V1 de developpement.
Ce choix doit etre re-evalue avant toute exposition reseau.

Objectif futur :
- utilisateurs systeme dedies
- droits filesystem minimaux
- services systemd durcis

### Pairing valide explicitement

Aucune machine ne doit etre ajoutee automatiquement a un reseau Dimension sans
validation explicite.

Le pairing devra etre concu comme une operation volontaire, visible et auditable.

### Logs utiles sans fuite de secrets

Les logs doivent permettre de comprendre l'etat du systeme sans exposer :
- secrets
- tokens
- cles privees
- mots de passe
- donnees personnelles inutiles

Les erreurs doivent etre suffisamment precises pour diagnostiquer, mais pas au
point de divulguer des informations sensibles.

---

## Checklist avant exposition reseau

Avant de binder un service sur le LAN ou WireGuard :

- [ ] authentification definie
- [ ] protocole documente
- [ ] ports documentes
- [ ] portee reseau documentee
- [ ] firewall configure
- [ ] secrets sortis du depot Git
- [ ] permissions filesystem verifiees
- [ ] utilisateur systeme evalue
- [ ] tests LAN effectues
- [ ] rollback possible
- [ ] logs verifies
- [ ] absence de fuite de secrets dans les logs verifiee

---

## Durcissement systemd actuel

Les services Dimension existants utilisent un durcissement systemd minimal :
- `NoNewPrivileges=true`
- `PrivateTmp=true`
- `ProtectSystem=strict`
- `ProtectHome=true`
- `LockPersonality=true`
- `MemoryDenyWriteExecute=true`
- `SystemCallArchitectures=native`

Les services qui ont besoin du reseau local limitent les familles d'adresses a :
- `AF_UNIX`
- `AF_INET`
- `AF_INET6`

Cela concerne actuellement :
- `dimension-node`
- `dimension-hub`

Les placeholders sans besoin reseau limitent les familles d'adresses a :
- `AF_UNIX`

Cela concerne actuellement :
- `dimension-network`
- `dimension-remote`
- `dimension-storage`

Utilisateurs systeme dedies :
- `dimension-node` tourne avec `User=dimension-node` et `Group=dimension-node`
- `dimension-hub` tourne avec `User=dimension-hub` et `Group=dimension-hub`

Chemins explicitement autorises en ecriture :
- `dimension-node` : `/var/lib/dimension/node`, `/var/log/dimension`
- `dimension-hub` : `/var/lib/dimension-hub`, `/var/log/dimension-hub`, `/etc/dimension/hub`

Les placeholders restent sans utilisateur dedie pour l'instant car ils ne font
qu'executer un `oneshot` sans logique reelle. Cette decision devra etre revue
quand ils deviendront des services persistants.

---

## Risques futurs

### Hub compromis

Impact possible :
- controle du registre machines
- exposition des metadonnees du reseau Dimension
- tentative de propagation vers les nodes
- manipulation future de pairing ou sync

Mesures a prevoir :
- authentification forte
- permissions minimales
- separation des secrets
- logs d'audit
- sauvegarde et rollback

### Node compromis

Impact possible :
- usurpation d'une machine Dimension
- acces aux informations locales
- pivot vers Hub ou autres machines
- manipulation de l'etat local

Mesures a prevoir :
- identite node protegee
- pairing explicite
- isolation systemd
- limitation des droits
- rotation/revocation des identites

### Fuite de cle WireGuard

Impact possible :
- acces non autorise au reseau Dimension
- contournement partiel du LAN physique
- scan ou tentative d'acces aux services internes

Mesures a prevoir :
- stockage securise des cles
- rotation des cles
- revocation simple
- segmentation des droits reseau
- logs de connexion

### Partage /home trop large

Impact possible :
- exposition de donnees personnelles
- ecriture non autorisee
- propagation d'erreurs ou suppressions
- confusion entre machines

Mesures a prevoir :
- permissions strictes
- partage opt-in
- montage en lecture seule quand possible
- separation utilisateur/machine
- confirmation avant actions destructives

### Streaming non autorise

Impact possible :
- acces a une session graphique
- controle clavier/souris non desire
- fuite d'ecran ou de contenu personnel
- reveil machine non voulu

Mesures a prevoir :
- autorisation explicite
- pairing fort
- notifications visibles
- controles de session
- WOL configure dans l'onboarding
- possibilite de desactivation rapide

---

---

## Revue securite - Hub local avec token

Cette section documente les points valides et les limites restantes apres la
mise en place du token local de developpement Hub/Node.

### Points valides

**Hub bind sur 127.0.0.1**
Le Hub ecoute uniquement sur `127.0.0.1` (defaut dans `modules/hub/default.nix`
et confirme dans `hosts/main/configuration.nix`). Aucun port n'est ouvert dans
le firewall. Aucune interface reseau externe n'est atteinte.

**Token non versionne**
Le token n'est pas stocke dans Git. Seul le chemin du fichier est configure
dans `hosts/main/configuration.nix`. Le contenu du fichier est cree
manuellement sur la machine apres le premier `nixos-rebuild`.

**Emplacement et permissions du fichier token**
- Repertoire : `/etc/dimension/secrets`
- Mode repertoire : `0750 root:dimension-secrets`
- Mode fichier attendu : `0640 root:dimension-secrets`
- Le groupe `dimension-secrets` est declare dans NixOS et ses membres sont
  uniquement `dimension-hub` et `dimension-node`.
- Root seul peut modifier le fichier.

**Utilisateurs systeme dedies**
- `dimension-hub` tourne avec `User=dimension-hub`, `Group=dimension-hub`
- `dimension-node` tourne avec `User=dimension-node`, `Group=dimension-node`
- Durcissement systemd applique sur les deux services :
  `NoNewPrivileges`, `PrivateTmp`, `ProtectSystem=strict`, `ProtectHome`,
  `LockPersonality`, `MemoryDenyWriteExecute`, `SystemCallArchitectures=native`

**Aucun LAN expose**
Aucune regle firewall n'est ajoutee. Aucun bind autre que `127.0.0.1` n'est
configure. Les familles d'adresses des services sont limitees a
`AF_UNIX`, `AF_INET`, `AF_INET6` (necessaire pour loopback uniquement).

**GET /ping reste public mais local**
L'endpoint `/ping` ne necessite pas de token. Il reste accessible uniquement
via `127.0.0.1`. Il ne divulgue aucune information sensible.

**POST /nodes/ping et GET /nodes proteges par token**
Quand `devTokenFile` est configure et que le fichier existe et est non vide,
le Hub exige le header `Authorization: Bearer <token>` sur ces deux endpoints.
Le Hub retourne `401` si le token est absent ou incorrect.
Le token n'est jamais loggue.

**Node envoie le token sans le logguer**
Quand `hubTokenFile` est configure, le Node lit le token au demarrage et
l'inclut dans le header `Authorization: Bearer` de chaque `POST /nodes/ping`.
Le token n'apparait pas dans les logs.

---

### Limites restantes

**Token de developpement partage**
Le token est un secret partage simple transmis en clair sur HTTP loopback.
Il n'offre pas d'authentification forte. Un processus local sur la meme
machine peut l'intercepter ou le lire s'il a acces au fichier ou au socket.
Ce mecanisme est suffisant pour un loopback local isole, pas pour un reseau.

**Pas encore de pairing**
N'importe quel client connaissant le token peut s'enregistrer comme node.
Il n'y a pas de validation d'identite cryptographique du node.
Toute machine ayant acces au loopback et au token peut injecter de faux nodes.

**Pas encore d'identite cryptographique**
Le `node_id` est un UUID genere localement, sans signature ni certificat.
Il n'y a aucun moyen de verifier qu'un node_id correspond bien a la machine
qui l'annonce.

**Pas encore de WireGuard**
Aucun VPN n'est configure. Le reseau Dimension est limite au loopback local.
Toute extension multi-machine necessitera WireGuard avant toute autre etape.

**Pas pret pour exposition LAN**
Avant de binder le Hub sur une interface LAN, la checklist complete de
`SECURITY.md` (section "Checklist avant exposition reseau") doit etre validee
dans son integralite. Le token de developpement local ne suffit pas.

---

## Etat actuel

- Hub ecoute sur `127.0.0.1:8787`
- Node poste son identite au Hub via `POST /nodes/ping` toutes les 60 secondes
- Hub maintient un registre local `nodes.json`
- Token local de developpement configure sur l'hote `main` :
  - chemin : `/etc/dimension/secrets/hub-dev-token`
  - permissions prevues : `0640 root:dimension-secrets`
  - fichier cree manuellement sur la machine, jamais dans Git
- Endpoints proteges : `POST /nodes/ping`, `GET /nodes`
- Endpoint public : `GET /ping`
- Aucune exposition LAN configuree
- Aucun WireGuard configure
- Aucun pairing implemente

Toute ouverture reseau doit etre traitee comme une phase explicite.
