# Dimension - Installateur

Ce document cadre le futur parcours d'installation de Dimension.

Etat actuel :
- aucun installateur graphique Dimension n'existe encore dans le depot
- un assistant CLI minimal `dimension-install` existe pour generer un
  `hosts/<nom>/configuration.nix` dans le repo
- cet assistant ne partitionne pas le disque et ne remplace pas
  `nixos-generate-config`

Objectif :
- installer Dimension depuis un seul ISO
- guider le choix d'une edition
- garder les choix avances comprehensibles
- produire une configuration NixOS reproductible

---

## Assistant CLI actuel

Commande :

```sh
dimension-install [host-id]
```

Ce script :
- detecte le repo Dimension courant
- demande le nom du host, l'edition, l'utilisateur principal et
  `system.stateVersion`
- genere `hosts/<host-id>/configuration.nix`

Limites actuelles :
- pas de partitionnement
- pas de detection Hub
- pas de pairing guide
- pas de creation automatique de `hardware-configuration.nix`
- pas d'ajout automatique du host dans `flake.nix`

Usage recommande :
1. lancer `dimension-install`
2. generer ou copier `hardware-configuration.nix` sur la machine cible
3. ajouter le nouveau host dans `flake.nix`
4. construire la configuration avec `nixos-rebuild` ou `nixos-install`

---

## Parcours prevu

### 1. Choix langue/clavier

L'utilisateur choisit la langue de l'installation et la disposition clavier.

Pour la V1, Dimension vise le francais par defaut, avec clavier francais.
Le parcours devra rester extensible a d'autres langues plus tard.

### 2. Choix disque

L'utilisateur choisit le disque cible et le mode de partitionnement.

Le parcours devra distinguer clairement :
- installation complete sur disque
- installation en VM
- cas avances a traiter plus tard

A ce stade, aucun partitionneur Dimension n'est implemente.

### 3. Choix edition Dimension

L'utilisateur choisit l'edition a installer :
- desktop
- laptop
- home-theatre
- server
- server-headless
- print-station
- gaming
- workstation

Le choix d'edition oriente la configuration de base via `dimension.edition`.
Seule l'edition `server-headless` doit rester sans desktop par defaut.
L'edition `server` peut avoir une interface graphique pour administrer
l'infrastructure localement.

Les logiciels specifiques a chaque edition viendront plus tard.

### 4. Creation utilisateur ou standalone

L'utilisateur choisit entre :
- creer un utilisateur local
- utiliser Dimension en mode standalone
- preparer une association a un compte Dimension plus tard

Le mode standalone doit permettre d'utiliser le systeme sans compte Dimension.
La synchronisation, le pairing et les preferences liees au compte pourront etre
ajoutees ensuite.

### 5. Hub detecte ou standalone

Si un Hub Dimension est detecte sur le reseau local, l'installateur pourra
proposer une association.

Si aucun Hub n'est disponible, l'installation continue en standalone.

A ce stade, dans l'installateur, la detection Hub et le pairing guide ne sont pas implementes.

### 6. Options complementaires

L'installateur pourra proposer des options complementaires simples.

Les apps Dimension doivent pouvoir rester optionnelles quand c'est pertinent,
afin de garder les editions modulaires.

Exception : le bureau a distance natif fait partie du socle Dimension attendu
et ne doit pas etre traite comme une simple application optionnelle a long terme.

Les logiciels optionnels, integrations par edition et services avances seront
ajoutes plus tard, et ne font pas partie du socle actuel.

Le comportement alimentation, reveil et WOL ne doit pas etre tranche dans
l'installation initiale. Il sera configure dans l'onboarding post-installation,
avec un contexte plus clair sur l'usage de la machine.

### 7. Resume avant installation

Avant d'ecrire sur le disque, l'installateur affiche un resume lisible :
- langue et clavier
- disque cible
- edition Dimension
- mode utilisateur ou standalone
- etat Hub ou standalone
- options complementaires choisies

L'installation ne demarre qu'apres confirmation explicite.

---

## Hors perimetre actuel

Ne sont pas implementes pour l'instant :
- installateur graphique Dimension
- partitionnement automatise Dimension
- detection Hub
- pairing
- compte Dimension
- selection de logiciels optionnels
- services par edition
- onboarding post-installation
- configuration alimentation/WOL
