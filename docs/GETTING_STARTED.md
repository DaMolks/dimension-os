# Getting Started

## Requirements

- Windows host with WSL2.
- Nix installed in WSL.
- Repo checked out at:

```text
E:\Projets\dimension-os
/mnt/e/Projets/dimension-os
```

## Enter The Repo

```powershell
wsl.exe --exec sh -lc 'cd /mnt/e/Projets/dimension-os && pwd'
```

## Check The Flake

```powershell
wsl.exe --exec sh -lc 'cd /mnt/e/Projets/dimension-os && /nix/var/nix/profiles/default/bin/nix flake check --no-build'
```

## Evaluate The Desktop Host

```powershell
wsl.exe --exec sh -lc 'cd /mnt/e/Projets/dimension-os && /nix/var/nix/profiles/default/bin/nix eval .#nixosConfigurations.desktop-test.config.system.build.toplevel.drvPath'
```

## Build The Installer ISO

```powershell
wsl.exe --exec sh -lc 'cd /mnt/e/Projets/dimension-os && /nix/var/nix/profiles/default/bin/nix build --max-jobs 1 --cores 1 .#nixosConfigurations.installer.config.system.build.isoImage'
```

Copy the ISO:

```powershell
wsl.exe --exec sh -lc 'cd /mnt/e/Projets/dimension-os && cp -f result/iso/dimension-os-installer.iso dimension-os-installer-YYYYMMDD.iso && sha256sum dimension-os-installer-YYYYMMDD.iso'
```

## If WSL Breaks During ISO Build

```powershell
wsl.exe --shutdown
```

Then retry the ISO build with `--max-jobs 1 --cores 1`.

## Rebuild An Installed System

On the installed NixOS system:

```sh
sudo nixos-rebuild switch --flake /etc/dimension#<hostname>
```

## Do Not Commit

- ISO files.
- `/result` symlink.
- `.claude/`.
- local secret files.
- `/etc/dimension/secrets/*`.
