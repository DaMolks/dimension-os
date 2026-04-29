# Claude / Agent Guide

This file is the short operational guide for agents working in this repo.

## Environment

Development happens on Windows. Nix runs through WSL2.

Repo path:

```text
E:\Projets\dimension-os
/mnt/e/Projets/dimension-os
```

Use this Nix binary in WSL:

```sh
/nix/var/nix/profiles/default/bin/nix
```

## Rules

- Do not commit secrets.
- Do not commit ISO artifacts unless the user explicitly asks for binary release artifacts in Git.
- Treat `docs/legacy/` as archive-only.
- Keep current docs in `docs/*.md`.
- New host configs go in `hosts/<name>/configuration.nix`; flake host discovery is automatic.
- Prefer small, validated changes. Run `nix flake check --no-build` after Nix edits.

## Validation Commands

```powershell
wsl.exe --exec sh -lc 'cd /mnt/e/Projets/dimension-os && /nix/var/nix/profiles/default/bin/nix flake check --no-build'
wsl.exe --exec sh -lc 'cd /mnt/e/Projets/dimension-os && /nix/var/nix/profiles/default/bin/nix eval .#nixosConfigurations.desktop-test.config.system.build.toplevel.drvPath'
wsl.exe --exec sh -lc 'cd /mnt/e/Projets/dimension-os && /nix/var/nix/profiles/default/bin/nix build --max-jobs 1 --cores 1 .#nixosConfigurations.installer.config.system.build.isoImage'
```

If WSL/Nix crashes during ISO build:

```powershell
wsl.exe --shutdown
```

Then retry with `--max-jobs 1 --cores 1`.

## Current Priority

Fix the VM blockers documented in [docs/STATUS.md](docs/STATUS.md):

1. GRUB theme syntax error in installer ISO.
2. SDDM custom theme not loading.
3. SDDM login failure while TTY login works.

## Architecture Shortcut

- `flake.nix`: inputs, host discovery, module exports.
- `modules/profiles`: edition composition layer.
- `modules/base`: shared system defaults and installer helper.
- `modules/desktop`: Plasma 6 base desktop.
- `modules/kde-config`: KDE defaults, plasma-manager home config, KWin/Konsole defaults.
- `modules/theme`: color scheme, fonts, Kvantum, Klassy.
- `modules/sddm`: custom SDDM theme package.
- `modules/plymouth`: boot splash.
- `modules/hub` and `modules/node`: local Hub/Node prototype.

## Legacy Docs

The old documentation was archived during the 2026-04-29 consolidation:

```text
docs/legacy/2026-04-29-pre-consolidation/
```

Use it for historical context only.
