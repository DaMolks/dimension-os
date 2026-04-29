# Dimension - Architecture

## Stack

OS : NixOS  
DE : KDE Plasma Wayland  
UI apps : Tauri + React  
Backend local : Node ou Rust  
Hub : Node ou Go + SQLite  
VPN : WireGuard  
Streaming : Sunshine + Moonlight  
Stockage : SMB + SFTP  

---

## Composants

### Dimension Node

- agent local
- gère :
  - réseau
  - pairing
  - sessions
  - stockage
  - widgets
  - sync

---

### Dimension Hub

- API HTTP + WebSocket
- base SQLite
- gestion :
  - machines
  - comptes
  - VPN
  - sync

---

### Dimension Search

- launcher global
- providers :
  - apps
  - fichiers
  - machines
  - commandes
- widgets dynamiques

---

### Dimension Shell

- dock
- search UI
- widgets
- animations

---

### Dimension Settings

- app paramètres
- mode simple/avancé

---

### Dimension Update

- vérifie updates
- rebuild Nix
- rollback

---

## Communication

Node ↔ Hub :
- HTTPS
- WebSocket

Node ↔ Node :
- LAN direct + VPN

---

## Sessions

- SDDM
- sessions locales + streaming
- wrapper Moonlight

---

## Stockage

- SMB pour UX
- SFTP pour admin
- montage automatique

---

## Sécurité

- clés locales
- Hub stocke public uniquement
- VPN obligatoire