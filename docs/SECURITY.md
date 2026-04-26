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

## Etat actuel

Actuellement :
- le Hub de test local ecoute sur `127.0.0.1`
- le Node peut ping le Hub local si `dimension.node.hubUrl` est defini
- aucune exposition LAN n'est configuree
- aucune API complete n'est disponible
- aucune authentification n'est implementee
- aucun WireGuard n'est configure

Toute ouverture reseau doit etre traitee comme une phase explicite.
