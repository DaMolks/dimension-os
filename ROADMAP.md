# Dimension - Roadmap

## Phase 1 - Base

Status: complete

- flake structure in place
- generic `main` host
- shared `base` module
- reproducible evaluation through `nix flake check`

---

## Phase 2 - Desktop Foundation

Status: complete

- KDE Plasma 6 on Wayland
- SDDM
- NetworkManager
- PipeWire
- Bluetooth
- baseline desktop packages

---

## Phase 3 - Editions

Status: complete

- `dimension.edition`
- desktop, laptop, server, server-headless, print-station, gaming, workstation
- edition-driven defaults

---

## Phase 4 - Installer Direction

Status: partially complete

Done:
- installer flow documented
- minimal CLI helper `dimension-install`

Still missing:
- host auto-registration in `flake.nix`
- hardware config generation flow
- graphical installer
- ISO install UX

---

## Phase 5 - Current Runtime Modules

Status: mixed

Real and usable in local or opt-in form:
- `hub`: minimal local HTTP registry using `nodes.json`
- `node`: minimal local agent posting identity to the Hub
- `wireguard`: foundational `dimension0` interface module, disabled by default
- `storage`: Samba, wsdd, and SFTP options
- `remote`: Sunshine and Wake-on-LAN options
- `apps`: Dimension desktop entries
- `kde-config`: KRunner, Baloo, default panel
- `theme`: wallpaper, color scheme, SDDM branding

Still placeholder or incomplete:
- `network`: still a placeholder around NetworkManager and `/etc/dimension`

---

## Phase 6 - Product Stabilization

Status: current priority

- keep documentation aligned with the real repository state
- add smoke tests for key hosts and services
- normalize file encoding and remove remaining mojibake
- define clear runtime contracts for Hub, Node, and host onboarding

---

## Phase 7 - Network Backbone

Status: next major engineering phase

- define Hub-managed network identity model
- move from loopback-only local dev to a safe LAN/VPN architecture
- document secrets, key rotation, and peer lifecycle

---

## Phase 8 - Hub / Node Evolution

Status: planned

- migrate Hub persistence to a stronger backend when needed
- add pairing approval workflow
- improve Node retry, health, and local state handling
- expose a more stable internal API contract

---

## Phase 9 - Shared Storage

Status: planned

- automatic mount strategy for approved machines
- permissions model for shared paths
- machine-aware storage discovery

---

## Phase 10 - Search, Settings, and Shell

Status: planned

- Dimension-specific search provider
- real Dimension Settings application
- widgets
- longer-term custom shell work

---

## Phase 11 - Quality and Release Readiness

Status: planned

- NixOS VM tests
- host validation matrix
- security review
- upgrade and rollback guidance
- real-machine validation
