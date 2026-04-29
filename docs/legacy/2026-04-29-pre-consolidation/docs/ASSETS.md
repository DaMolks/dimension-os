# Dimension - Workflow assets visuels

Ce document definit comment demander, recevoir, decouvrir et integrer les
assets visuels de Dimension. Il s'applique a chaque fois qu'une tache
requiert une image, une icone, un fond d'ecran ou tout autre element graphique.

---

## Regle fondamentale

**Un agent ne doit jamais inventer un asset definitif sans brief explicite.**

Si une tache necessite un asset visuel, l'agent produit un **brief d'asset**
precis (voir template ci-dessous) et attend la livraison avant de continuer.
Un placeholder technique temporaire (carre de couleur, fichier vide trace) peut
etre utilise pour debloquer l'integration, mais il est toujours marque comme
provisoire et remplace a la premiere occasion.

---

## Types d'assets

### Logo Dimension

Utilisation : ecran de connexion, installateur, a-propos, splash, icone app.

Variantes attendues :
- logo complet (symbole + texte "Dimension")
- symbole seul (carre ou rond, utilisable en icone)
- version monochromatique (blanc, noir, vert uni)
- version adaptee fond clair et fond sombre

Format : SVG source + exports PNG aux tailles cibles.

### Icones systeme (remplacement ou complement Papirus)

Icones qui completent ou remplacent le pack Papirus pour les apps Dimension
et les elements specifiques a l'OS (Hub, Node, Search, etc.).

Format : planche PNG (voir section Format planches).

### Icones Dimension

Icones des apps et fonctionnalites Dimension propres :
- Dimension Search
- Dimension Hub
- Dimension Node
- Dimension Settings
- Dimension Update
- Dimension Dock
- Panneau systeme

Format : planche PNG (voir section Format planches) + SVG source.

### Fonds d'ecran

Utilisation : bureau, ecran de verrouillage, SDDM.

Variantes attendues :
- version Light (fond clair)
- version Dim (fond sombre)
- format 16:9, 16:10, 21:9 (ultra-large)
- resolution minimale : 2560x1440

Style : abstrait ou spatial, sobre, sans texte, coherent avec la palette
vert Dimension.

Format : PNG ou JPEG haute qualite.

### Assets SDDM

Elements specifiques a l'ecran de connexion :
- fond SDDM (peut etre le meme que le fond bureau ou une variante)
- logo positionne sur fond SDDM
- indicateur de champ de saisie
- bouton de session / icone utilisateur

Format : PNG transparent pour les elements superposes, PNG plein pour les fonds.

### Assets installateur

Elements de l'ecran d'installation :
- fond installateur
- logo positionne
- illustrations etapes (optionnel, phase tardive)

Format : PNG.

### Assets apps maison

Chaque app Dimension (Search, Settings, Hub UI, etc.) peut avoir ses propres
illustrations internes (ecrans vides, etats d'erreur, onboarding).

Format : SVG source + exports PNG.

---

## Format des planches d'icones

Quand des icones sont livrees en lot, le format de planche suivant est attendu :

| Parametre        | Valeur attendue                         |
|------------------|-----------------------------------------|
| Format fichier   | PNG, fond transparent                   |
| Disposition      | grille reguliere, rangees et colonnes   |
| Taille grille    | 4x4 ou 5x5 icones par planche          |
| Taille cellule   | 256x256 px                              |
| Padding par cel. | 16 px de chaque cote (icone : 224x224) |
| Texte            | aucun (pas de label, pas de numero)     |
| Style            | minimal / spatial / sobre               |
| Couleur accent   | vert Dimension (a preciser dans le brief)|
| Fond             | transparent (pas de fond colore)        |

Une planche 4x4 contient 16 icones. Une planche 5x5 en contient 25.
Si le lot depasse la capacite d'une planche, livrer plusieurs fichiers
numerotes (`icons-01.png`, `icons-02.png`, ...).

---

## Structure cible du depot

```
assets/
  icons/
    source/          # SVG sources ou planches PNG originales non decoupees
    256/             # icones individuelles 256x256 px
    128/             # icones individuelles 128x128 px
    64/              # icones individuelles 64x64 px
  wallpapers/        # fonds d'ecran haute resolution
  logos/             # logo Dimension (SVG + exports PNG)
  sddm/              # assets specifiques SDDM
  installer/         # assets specifiques installateur
```

Le repertoire `assets/` est a la racine du depot.
Il n'est pas encore cree : il sera initialise quand les premiers assets
sont livres.

Les fichiers sources (SVG, planches PNG) vont dans `source/` ou dans le
sous-repertoire correspondant. Les exports decoupes et redimensionnes vont
dans les sous-repertoires par taille.

---

## Template de brief d'asset

A utiliser pour toute demande d'asset a un illustrateur ou a un modele d'IA.

```
BRIEF ASSET - Dimension OS
==========================

Type d'asset : [icone / logo / fond d'ecran / illustration / ...]
Quantite     : [nombre d'elements ou de planches]
Destination  : [SDDM / bureau / app X / icone systeme / ...]

Style
-----
- minimal, spatial, sobre
- pas de rendu photo-realiste
- pas de texte dans l'image
- coherent avec un OS desktop moderne

Palette
-------
- accent : vert Dimension (HSL approximatif : 145°, 45%, 40%)
- fond transparent pour les icones
- fond neutre pour les illustrations (si applicable)

Format de livraison
-------------------
- planches PNG 256x256 px par cellule, grille 4x4 ou 5x5
- SVG source si possible
- fond transparent

Elements a representer
----------------------
[liste numerotee des icones ou scenes a illustrer]
1. ...
2. ...
...

Notes specifiques
-----------------
[contraintes ou details importants pour cette commande]

Exemples de reference (optionnel)
----------------------------------
[styles, projets ou assets existants dont s'inspirer]
```

---

## Template de decoupage et integration

A utiliser quand une planche d'icones est livree et doit etre decoupee
puis integree dans `assets/icons/`.

### Etape 1 - Verifier la planche

- confirmer la taille totale (ex : 4x4 = 1024x1024 px avec cellule 256x256)
- confirmer le nombre d'icones (ex : 16 pour 4x4)
- confirmer que le fond est transparent
- noter l'ordre de lecture (gauche → droite, haut → bas)

### Etape 2 - Decoupe

Outil recommande : `imagemagick` (disponible dans nixpkgs sous `imagemagick`).

Exemple pour une planche 4x4 (cellule 256x256, 16 icones) :

```sh
# Extraire chaque cellule avec un nom explicite
# icone ligne 0, colonne 0 = crop 256x256 depuis le coin 0,0
convert source.png -crop 256x256+0+0    +repage icon-00.png
convert source.png -crop 256x256+256+0  +repage icon-01.png
convert source.png -crop 256x256+512+0  +repage icon-02.png
convert source.png -crop 256x256+768+0  +repage icon-03.png
# continuer pour chaque ligne...

# Redimensionner a 128x128
convert icon-00.png -resize 128x128 ../128/icon-00.png

# Redimensionner a 64x64
convert icon-00.png -resize 64x64   ../64/icon-00.png
```

Script de decoupage automatique (adapter `COLS`, `ROWS`, `CELL`, `PREFIX`) :

```sh
#!/usr/bin/env bash
PLANCHE="$1"
PREFIX="${2:-icon}"
COLS=4
ROWS=4
CELL=256

for row in $(seq 0 $((ROWS - 1))); do
  for col in $(seq 0 $((COLS - 1))); do
    idx=$(( row * COLS + col ))
    x=$(( col * CELL ))
    y=$(( row * CELL ))
    name=$(printf '%s-%02d.png' "$PREFIX" "$idx")
    convert "$PLANCHE" -crop "${CELL}x${CELL}+${x}+${y}" +repage \
      "assets/icons/256/${name}"
    convert "assets/icons/256/${name}" -resize 128x128 \
      "assets/icons/128/${name}"
    convert "assets/icons/256/${name}" -resize 64x64 \
      "assets/icons/64/${name}"
  done
done
```

### Etape 3 - Nommer les fichiers

Nommer les icones selon leur usage, pas leur position dans la planche :

```
icon-dimension-search.png
icon-dimension-hub.png
icon-dimension-node.png
icon-dimension-settings.png
...
```

### Etape 4 - Integrer dans NixOS

Pour installer des icones dans le systeme via un module Nix :

```nix
environment.systemPackages = [
  (pkgs.runCommand "dimension-icons" {} ''
    mkdir -p $out/share/icons/Dimension/256x256/apps
    cp ${./assets/icons/256}/*.png \
       $out/share/icons/Dimension/256x256/apps/
  '')
];
```

Le theme d'icones `Dimension` sera selectionnable dans KDE System Settings
une fois ce paquet installe.

---

## Suivi des assets

| Asset                  | Statut      | Fichier(s)                  |
|------------------------|-------------|------------------------------|
| Logo Dimension         | a faire     | -                            |
| Icones apps Dimension V1 | integrees provisoires | `assets/icons/256/dimension-search.png`, `assets/icons/256/dimension-hub.png`, `assets/icons/256/dimension-settings.png` |
| Fond d'ecran Light     | a faire     | -                            |
| Fond d'ecran Dim       | a faire     | -                            |
| Theme SDDM             | a faire     | -                            |
| Icones systeme         | a faire     | -                            |

Note : les icones apps Dimension V1 sont validees pour l'integration actuelle
meme si la transparence n'est pas parfaite. Elles sont installees via le
fallback `hicolor` pour les entrees `.desktop` existantes.

Ce tableau est mis a jour a chaque livraison d'asset.
