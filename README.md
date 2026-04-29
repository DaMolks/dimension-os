# Dimension OS

> Personal NixOS, declarative by design, built for a local-first multi-machine future.

Dimension OS is a modular NixOS flake for building a coherent personal operating system: KDE Plasma 6 today, Dimension shell ideas tomorrow, and a Hub/Node backbone for local machines, storage, remote sessions, and WireGuard.

The project is early, opinionated, and intentionally reproducible. The repo is the source of truth.

## What Exists Now

- NixOS flake with automatic host discovery.
- Edition system: `desktop`, `laptop`, `home-theatre`, `server`, `server-headless`, `print-station`, `gaming`, `workstation`.
- Installer ISO target with a CLI installer and disko-based GPT/EFI/ext4 layout.
- KDE Plasma 6 desktop stack with SDDM, PipeWire, NetworkManager, Bluetooth, Papirus, Kvantum, Klassy, and plasma-manager.
- Dimension visual assets: wallpapers, logo, Plymouth splash, SDDM background.
- Local Hub service with a small HTTP API and pending node registry.
- Local Node service that can ping the Hub and persist local state.
- WireGuard foundation module, disabled by default.
- Optional storage and remote modules: Samba/wsdd/SFTP, Sunshine, Wake-on-LAN.

## Current Truth

Phase 2 is implemented but not validated. The latest VM test found three blockers:

- GRUB theme syntax error at boot: `progress_bar` needs investigation in the installer theme.
- SDDM falls back to an ugly/default-looking greeter instead of the Dimension glass theme.
- SDDM rejects login while the same user/password works on TTY, likely keyboard layout or greeter fallback related.

Start with [docs/STATUS.md](docs/STATUS.md) and [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) before building a new ISO.

## Repository Map

```text
assets/       Wallpapers, icons, boot/login visual assets
docs/         Current documentation, consolidated on 2026-04-29
hosts/        Host configurations auto-discovered by flake.nix
modules/      Dimension NixOS modules
mockups/      UI mockups and experiments
docs/legacy/  Archived documentation before the consolidation
```

## Quick Commands

Run Nix from WSL2:

```powershell
wsl.exe --exec sh -lc 'cd /mnt/e/Projets/dimension-os && /nix/var/nix/profiles/default/bin/nix flake check --no-build'
wsl.exe --exec sh -lc 'cd /mnt/e/Projets/dimension-os && /nix/var/nix/profiles/default/bin/nix eval .#nixosConfigurations.desktop-test.config.system.build.toplevel.drvPath'
wsl.exe --exec sh -lc 'cd /mnt/e/Projets/dimension-os && /nix/var/nix/profiles/default/bin/nix build --max-jobs 1 --cores 1 .#nixosConfigurations.installer.config.system.build.isoImage'
```

Copy the built ISO to the workspace:

```powershell
wsl.exe --exec sh -lc 'cd /mnt/e/Projets/dimension-os && cp -f result/iso/dimension-os-installer.iso dimension-os-installer-YYYYMMDD.iso && sha256sum dimension-os-installer-YYYYMMDD.iso'
```

## Documentation

- [Current status](docs/STATUS.md)
- [Getting started](docs/GETTING_STARTED.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Module catalog](docs/MODULES.md)
- [Installer and ISO](docs/INSTALLER.md)
- [Desktop and theming](docs/DESKTOP.md)
- [Runtime services](docs/RUNTIME.md)
- [Hub API](docs/API.md)
- [Security](docs/SECURITY.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Roadmap](docs/ROADMAP.md)
- [Legacy archive](docs/LEGACY.md)

## Project Direction

Dimension aims to become a personal OS layer where machines feel like one environment:

- local-first identity,
- explicit pairing,
- safe WireGuard mesh,
- unified search,
- coherent desktop visuals,
- shared storage,
- streaming sessions,
- declarative recovery and rollback.

For now, the priority is brutally practical: make the installer ISO boot cleanly, make SDDM reliable, and keep the documentation aligned with the real repo.
