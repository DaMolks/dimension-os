# Dimension - Thème et identité visuelle

Ce document decrit la direction du design de Dimension : identite visuelle,
composants de l'interface, strategie d'integration et limites actuelles.

Il sert de reference pour les futures phases d'implementation graphique.

---

## Etat d'implementation actuel

Le module `modules/theme` pose uniquement les paquets visuels de base.
Aucun thème n'est applique automatiquement : la selection se fait via
KDE System Settings ou les futurs outils Dimension.

Paquets installes quand `dimension.theme.enable = true` :

| Paquet                           | Role                                      |
|----------------------------------|-------------------------------------------|
| `papirus-icon-theme`             | Pack d'icones Papirus                     |
| `layan-cursors`                  | Curseur de la famille Layan               |
| `kdePackages.qtstyleplugin-kvantum` | Moteur de thème Qt SVG (Kvantum)       |

Note : `layan-kde` (thème Plasma complet) n'est pas package dans nixpkgs.
Un scheme de couleurs KDE dedie sera ajoute dans une prochaine etape.

Le theme est active automatiquement pour toutes les editions avec desktop
(`dimension.theme.enable = lib.mkDefault (edition != "server-headless")`).
L'edition `server-headless` (dont `main` en configuration actuelle) ne
l'active pas.

---

## Identite visuelle

### Base

Le design de Dimension s'inspire du thème KDE Layan :
- geometrie propre, coins arrondis, surfaces planes
- pas d'ornements inutiles
- emphasis sur la lisibilite et la coherence

Ce n'est pas une copie de Layan : Layan sert de socle, Dimension y superpose
sa propre palette et ses propres conventions visuelles.

### Palette

Couleur principale : vert Dimension
- vert desature, profond, pas agressif
- utilisable sur fond clair et fond sombre sans perte de lisibilite
- teinte unique coherente sur tous les composants : boutons, focus, accents,
  icones actives, indicateurs

La palette ne contient pas de couleur d'accent secondaire. Le vert Dimension
est la seule couleur fonctionnelle.

### Variantes

**Dimension Light**
- fond blanc casse / gris tres clair
- texte sombre
- surfaces legèrement elevees par ombre douce
- accent vert Dimension

**Dimension Dim**
- fond gris fonce / ardoise (pas noir pur)
- texte blanc / gris clair
- surfaces avec elevation subtile
- accent vert Dimension

Les deux variantes partagent la meme geometrie, les memes proportions et le
meme jeu d'icones. Seules les valeurs de couleur changent.

Il n'y a pas de variante "sombre extreme" (noir pur) dans la V1.

---

## Composants de l'interface

### Dock

- positionne en bas, centre horizontalement
- contient les apps epinglees et les apps ouvertes
- auto-hide configurable (masquage quand une fenetre occupe la zone)
- hauteur et taille des icones fixes par le theme, pas par l'utilisateur en V1
- bouton systeme a droite du dock (ouvre le panneau systeme)
- pas de barre des taches classique en haut ou en bas

### Dimension Search

Declencheur : touche Super

Comportement :
- le dock se transforme en barre de recherche (morph anime)
- animation fluide avec effet blur sur le contenu derriere
- les widgets apparaissent sous la barre

Sans saisie :
- grille de widgets personnalises scrollable

Avec saisie :
- resultats : apps, fichiers, machines, commandes, actions systeme
- widgets contextuels selon le type de resultat

Validation :
- si match → action directe
- si pas de match → recherche web

### Widgets

- affichage en grille avec scroll vertical
- tailles multiples (cellules de 1x1, 2x1, 2x2...)
- mode edition global pour repositionner ou supprimer
- bouton discret pour ajouter un widget
- types prevus : machines Dimension, imprimantes, systeme, fichiers, raccourcis

### Panneau systeme

- overlay immersif (occupe une partie de l'ecran, fond flou)
- declenche par le bouton systeme du dock
- fermeture au clic a l'exterieur du panneau

Contenu prevu :
- Wi-Fi, Bluetooth, Volume, Luminosite, Batterie
- VPN / WireGuard
- CPU / RAM / reseau
- actions systeme (verrouiller, redemarrer, eteindre)

Clic long sur un element → acces aux reglages avances de ce composant

### Ecran de connexion (SDDM)

- theme SDDM coherent avec Dimension Light / Dim
- fond neutre avec logo Dimension
- champ utilisateur + mot de passe sans surcharge visuelle
- pas d'animation complexe au login

---

## Contraintes de design

**Pas de mode kiosque**
Dimension est un bureau classique. L'utilisateur garde acces complet a ses
applications, a son bureau et a ses reglages. Aucun verrouillage d'interface.

**KDE Plasma Wayland**
Le bureau s'appuie sur KDE Plasma en session Wayland. Pas de fork de
compositeur, pas de DE custom en V1.

**Interface en francais par defaut**
La langue systeme par defaut est le francais. Les composants Dimension propres
(Search, panneau, widgets, parametres) seront integralement en francais.

**Animations fluides mais sobres**
Les animations sont presentes mais courtes et non bloquantes :
- duree cible : 150-250 ms
- pas de rebond, pas d'effet physique exagere
- desactivables via les reglages d'accessibilite KDE

---

## Strategie d'integration : deux phases

### Phase 1 - KDE natif

La premiere integration du thème passe par les mecanismes KDE existants :

| Composant          | Moyen d'integration                         |
|--------------------|---------------------------------------------|
| Couleurs           | palette KDE (`colors` + `colorscheme`)      |
| Decorations        | `kwin-decoration` base Layan modifie        |
| Icons              | pack d'icones derive ou Papirus tinte vert  |
| Curseur            | curseur coherent avec la palette            |
| SDDM               | theme SDDM dedie                            |
| Dock               | Latte Dock ou KDE Panel configure           |
| Widgets            | Plasmoids KDE existants + custom simples    |
| Panneau systeme    | System Tray KDE + layout custom             |
| Dimension Search   | KRunner + layout personnalise               |

Cette phase permet de valider l'identite visuelle sur une base stable sans
ecrire de code de shell.

### Phase 2 - Dimension Shell custom

Une fois l'identite visuelle validee, les composants critiques deviennent
des applications Dimension propres :

| Composant          | Remplacement prevu                          |
|--------------------|---------------------------------------------|
| Dock               | `dimension-dock` (app native QML/C++)       |
| Dimension Search   | `dimension-search` (app native)             |
| Widgets            | `dimension-widgets` (moteur de widgets)     |
| Panneau systeme    | `dimension-panel` (overlay natif)           |

KDE Plasma reste le compositeur et le gestionnaire de fenetres. Dimension Shell
remplace uniquement la couche visuelle interactive, pas le DE complet.

Le calendrier de cette transition est defini dans ROADMAP.md (Phase 11).

---

## Ce qui n'est pas encore defini

- valeur exacte du vert Dimension (hex, HSL)
- police d'interface (candidate : Noto Sans ou Inter)
- pack d'icones final
- comportement exact du morph dock → search
- specificites par edition (ex : gaming, workstation)
- reglages de taille d'ecran / HiDPI / multi-moniteur
