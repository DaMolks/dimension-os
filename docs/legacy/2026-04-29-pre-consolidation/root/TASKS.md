# Dimension - Tasks

## Completed

### Core structure

- [x] Create `flake.nix`
- [x] Create generic hosts
- [x] Create `base`, `desktop`, `profiles`, `hub`, `node`, `network`, `remote`, `storage`, `theme`, `apps`, and `kde-config` modules
- [x] Keep `nix flake check --no-build` passing

### Desktop and UX baseline

- [x] Enable KDE Plasma 6 and SDDM
- [x] Add Dimension desktop entries
- [x] Wire Dimension Search to KRunner
- [x] Add a default Plasma panel with pinned Dimension entries
- [x] Add a first Dimension visual identity: wallpaper, color scheme, SDDM theme
- [x] Extend Baloo indexing to `/mnt/dimension`

### Runtime baseline

- [x] Add a minimal local Hub HTTP service
- [x] Add a minimal local Node service
- [x] Add token-based local Hub/Node protection
- [x] Add opt-in Sunshine and Wake-on-LAN support
- [x] Add opt-in Samba, wsdd, and SFTP support
- [x] Add edition-specific defaults for gaming, workstation, print-station, and laptop
- [x] Add `dimension-install` CLI host generator

---

## Current Priority

### Documentation and repo truth

- [x] Align major docs with the actual repository state
- [ ] Normalize encoding in remaining mojibake files
- [ ] Review older docs for stale assumptions not yet cleaned up

### Network foundation

- [x] Restore or reintroduce the WireGuard module
- [x] Export it through `flake.nix`
- [ ] Decide how hosts opt into VPN identity
- [ ] Document key management and peer lifecycle

### Runtime contracts

- [ ] Define the supported Hub / Node protocol surface
- [ ] Document state files and ownership rules
- [ ] Document service responsibilities and lifecycle

### Validation

- [ ] Add a smoke test for `main`
- [ ] Add a smoke test for `desktop-test`
- [ ] Test storage opt-in paths
- [ ] Test remote opt-in paths

---

## Next Product Steps

### Hub / Node

- [ ] Improve Hub persistence beyond `nodes.json`
- [ ] Add explicit pairing
- [ ] Add safer LAN / VPN exposure rules
- [ ] Add stronger identity handling

### Search / Settings

- [ ] Add Dimension-specific search results
- [ ] Create a real Dimension Settings tool
- [ ] Add widgets and system actions integration

### Storage

- [ ] Define auto-mount behavior
- [ ] Define cross-machine path conventions
- [ ] Add approval-aware storage sharing

### Installer

- [ ] Auto-add generated hosts to `flake.nix`
- [ ] Improve generated host templates by edition
- [ ] Design a graphical installer flow

### Quality and security

- [ ] Review secrets handling across modules
- [ ] Add upgrade and rollback guidance
- [ ] Expand VM and real-machine validation
