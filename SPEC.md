# Dimension - Spécification

## Vision

Créer un OS personnel basé sur NixOS, orienté expérience utilisateur, multi-machines, avec intégration native du réseau, du streaming, du stockage et des outils.

Dimension doit être :
- simple à utiliser
- profondément intégré
- cohérent visuellement
- reproductible
- maintenable

---

## Identité

Nom : Dimension

Design :
- basé sur Layan
- style minimal, moderne, fluide
- couleurs : nuances de vert
- variantes :
  - Dimension Light
  - Dimension Dim

Cohérence obligatoire :
- KDE
- login
- installateur
- apps maison
- hub
- widgets

---

## Éditions d’installation

Dimension sera proposé depuis un seul ISO capable d’installer plusieurs éditions :
- desktop
- laptop
- server
- server-headless
- print-station
- gaming
- workstation

L’édition choisie oriente la configuration de la machine sans changer la base commune du système.

Par défaut, les éditions graphiques activent le bureau Dimension/KDE :
- desktop
- laptop
- server
- print-station
- gaming
- workstation

L’édition server peut donc avoir une interface graphique pour administrer l’infrastructure localement.
Seule l’édition server-headless est sans desktop par défaut.

---

## Expérience utilisateur

### Bureau

- KDE Plasma Wayland
- dock centré (apps épinglées + ouvertes)
- auto-hide configurable
- bouton système à droite

---

### Dimension Search

Touche : Super

Comportement :
- dock → morph en barre de recherche
- animation fluide + blur
- widgets apparaissent dessous

Sans saisie :
- widgets personnalisés (grille scrollable)

Avec saisie :
- résultats
- widgets contextuels

Entrée :
- si match → action
- sinon → recherche web

Fonctionnalités :
- apps
- fichiers
- machines
- commandes
- actions système

---

### Widgets

- grille avec scroll
- tailles multiples
- configurables
- mode édition global
- bouton discret pour ajouter

Types :
- machines
- imprimantes
- système
- fichiers
- raccourcis

---

### Panneau système

- overlay immersif
- ouvert via bouton dock
- fermeture clic extérieur

Contenu :
- Wi-Fi
- Bluetooth
- Volume
- Luminosité
- Batterie
- VPN
- CPU/RAM/réseau
- actions système

Clic long → réglages avancés

---

### Notifications

- non intrusives
- centre de notifications
- actions possibles
- pas de priorité visuelle différente

---

### Paramètres

- app dédiée
- mode simple + mode avancé (PIN)
- sections claires

---

## Compte Dimension

- email + mot de passe
- PIN local

Fonctions :
- synchronisation
- pairing
- accès machines
- préférences

Standalone :
- utilisable sans compte
- synchro plus tard
- fusion ou remplacement

---

## Réseau

- LAN + WireGuard uniquement
- Hub central obligatoire pour réseau étendu

---

## Hub Dimension

- tourne sur serveur Linux
- registre des machines
- VPN
- synchro
- pairing

---

## Pairing

- auto-détection LAN
- validation via :
  - autre machine
  - email
  - app mobile future

---

## Streaming

- Moonlight / Sunshine
- intégré comme session
- accessible depuis login

Fonctions :
- WOL automatique
- profils
- retour local

---

## Stockage

- accès /home de chaque machine
- SMB + SFTP
- montage automatique
- espace unifié "Dimension"

---

## Impression 3D

- Klipper + Moonraker
- gestion locale sur machine dédiée
- interface maison

---

## Mise à jour

- automatique avec validation
- reboot obligatoire
- rollback

---

## Sécurité

- pas de secrets en clair
- accès via VPN
- validation pairing
- logs internes

---

## Langue

- français uniquement (V1)
