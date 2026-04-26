# Dimension - Editions

Dimension est pense comme un OS generaliste installe depuis un seul ISO.
L'edition choisie doit orienter la configuration de la machine sans dupliquer
la base du systeme.

Etat actuel :
- l'option Nix est `dimension.edition`
- seule l'edition `server-headless` garde le desktop desactive
- les autres editions activent le desktop minimal via `dimension.desktop.enable`
- aucun logiciel specifique d'edition n'est encore ajoute

---

## desktop

Usage prevu :
- machine personnelle standard
- usage quotidien, navigation, fichiers, applications graphiques
- base simple pour une installation Dimension classique

Desktop :
- active

Fonctions futures envisagees :
- experience KDE/Dimension complete
- theme Dimension
- integration dock/search/widgets
- applications utilisateur de base

Pas encore implemente :
- theme Dimension
- dock custom
- Dimension Search
- widgets
- applications Dimension

---

## laptop

Usage prevu :
- ordinateur portable
- usage mobile avec batterie, Wi-Fi, Bluetooth et sessions graphiques
- variante proche de `desktop`, adaptee plus tard aux contraintes laptop

Desktop :
- active

Fonctions futures envisagees :
- gestion batterie avancee
- profils d'energie
- raccourcis clavier laptop
- meilleure integration Wi-Fi/Bluetooth
- reglages de luminosite et veille

Pas encore implemente :
- profils d'energie Dimension
- logique batterie specifique
- raccourcis laptop
- optimisations de veille

---

## server

Usage prevu :
- serveur administre localement avec interface graphique
- machine d'infrastructure Dimension avec console visuelle
- serveur familial, homelab ou machine centrale non headless

Desktop :
- active

Fonctions futures envisagees :
- interface d'administration Dimension
- supervision locale
- outils reseau
- gestion du Hub Dimension
- vues de statut pour services et machines

Pas encore implemente :
- Hub Dimension
- interface d'administration
- supervision
- services reseau avances
- stockage partage

---

## server-headless

Usage prevu :
- serveur sans interface graphique
- VM, machine distante, serveur minimal
- base neutre pour tests et deploiements automatises

Desktop :
- desactive

Fonctions futures envisagees :
- administration CLI
- services Dimension activables explicitement
- profil adapte aux environnements virtualises
- configuration serveur minimale et reproductible

Pas encore implemente :
- services Dimension
- Hub Dimension
- configuration d'administration distante
- stockage partage
- VPN Dimension

---

## print-station

Usage prevu :
- machine dediee a l'impression 3D
- station locale pour imprimantes, atelier ou ferme d'impression
- edition graphique pour pilotage et surveillance

Desktop :
- active

Fonctions futures envisagees :
- Klipper
- Moonraker
- interface Dimension d'impression
- supervision imprimantes
- profils d'atelier

Pas encore implemente :
- Klipper
- Moonraker
- UI print farm
- detection imprimantes
- automatisations atelier

---

## gaming

Usage prevu :
- machine de jeu locale
- poste graphique performant
- base future pour jeux et streaming

Desktop :
- active

Fonctions futures envisagees :
- optimisations gaming
- integration manettes
- profils performance
- streaming Moonlight/Sunshine plus tard
- lancement de jeux depuis l'interface Dimension

Pas encore implemente :
- Steam
- Sunshine
- Moonlight
- profils performance
- integrations gaming

---

## workstation

Usage prevu :
- poste de travail avance
- developpement, creation, administration ou usage intensif
- machine graphique complete mais generaliste

Desktop :
- active

Fonctions futures envisagees :
- outils de developpement
- outils de diagnostic
- workflows multi-machines
- integration avec le stockage Dimension
- widgets de productivite

Pas encore implemente :
- outils workstation specifiques
- stockage Dimension
- workflows multi-machines
- widgets avances
- integrations professionnelles
