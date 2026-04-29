# Installer And ISO

## Current Model

The installer host is:

```text
hosts/installer/configuration.nix
```

It builds a live ISO using the NixOS minimal installer module plus Dimension branding and the CLI installer.

Build command:

```powershell
wsl.exe --exec sh -lc 'cd /mnt/e/Projets/dimension-os && /nix/var/nix/profiles/default/bin/nix build --max-jobs 1 --cores 1 .#nixosConfigurations.installer.config.system.build.isoImage'
```

## Installer Flow

The live ISO auto-starts `dimension-install` on TTY1 as root.

The installer asks for:

- target disk,
- Dimension edition,
- hostname,
- main username,
- password.

It then:

- copies the flake to a temporary working path,
- writes a generated host config,
- partitions with disko,
- generates hardware config,
- copies the flake into `/mnt/etc/dimension`,
- runs `nixos-install --flake /mnt/etc/dimension#<hostname>`,
- sets the user password with `nixos-enter`.

## Disk Layout

The current disko module is:

```text
modules/installer/disko-simple.nix
```

Layout:

- GPT disk,
- EFI partition mounted at `/boot`,
- ext4 root partition mounted at `/`.

## Current Known Boot Bug

VM boot currently shows:

```text
error: (cd0)/EFI/BOOT/grub-theme/theme.txt:8:15 missing separator after property name `progress_bar`.
```

Likely fix in `hosts/installer/configuration.nix`:

```text
progress_bar {
boot_menu {
```

should become:

```text
+ progress_bar {
+ boot_menu {
```

Rebuild ISO after this fix.

## ISO Artifacts

ISO files are build artifacts. Keep them out of Git unless this repo becomes a release artifact store.
