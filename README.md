# Dimension OS

Dimension OS is a modular NixOS flake centered on KDE Plasma 6 and a future
local-first multi-machine workflow.

## Current State

The repository is in active prototype phase.

Implemented today:
- modular NixOS layout with edition-based profiles
- KDE Plasma 6 desktop stack with SDDM, PipeWire, Bluetooth, and theming
- Dimension Search entry wired to KRunner
- default Plasma panel with pinned Dimension entries
- opt-in mDNS/Avahi network foundation with optional Hub advertisement
- local development Hub and Node services with token-based protection
- manual Hub pairing approval workflow
- WireGuard foundation module with a `dimension0` interface, disabled by default
- Hub-distributed WireGuard peer list fetch and local Node persistence
- optional Hub auto-discovery for nodes when `hubUrl` is unset
- helper command `dimension-wg-keygen` for local WireGuard key generation
- opt-in storage services through Samba, wsdd, and SFTP
- opt-in remote services through Sunshine and Wake-on-LAN
- minimal interactive `dimension-install` helper for generating new host configs

Not implemented yet:
- production-grade Hub and Node protocol
- Hub-managed WireGuard interface application
- LAN-safe Hub exposure
- interactive pairing UX and stronger machine identity
- automatic shared storage mounting across machines
- native Dimension Settings app, widgets, and custom shell
- full installer UX from ISO

## Repository Layout

- `modules/` contains the NixOS modules
- `hosts/` contains declared host configurations
- `docs/` contains runtime, security, API, and product notes
- `assets/` contains icons and wallpapers shipped by the system

## Validation

From WSL2:

```sh
cd /mnt/e/Projets/dimension-os
nix flake check --no-build
```

## Primary Hosts

- `main`: local Hub/Node development host, `server-headless` by default
- `desktop-test`: visual validation host for desktop features
- `installer`: graphical Plasma 6 live ISO target for installer testing
