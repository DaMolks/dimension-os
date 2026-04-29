# Troubleshooting

## GRUB Theme Error In ISO

Symptom:

```text
error: (cd0)/EFI/BOOT/grub-theme/theme.txt:8:15 missing separator after property name `progress_bar`.
```

Likely fix:

```text
progress_bar {
boot_menu {
```

should be:

```text
+ progress_bar {
+ boot_menu {
```

File:

```text
hosts/installer/configuration.nix
```

Rebuild ISO after editing.

## SDDM Theme Falls Back

Symptoms:

- Login screen looks plain/basic.
- Dimension glass card is missing.
- Session selector exists.
- User name appears correctly.

Commands in VM:

```sh
journalctl -u display-manager -b --no-pager
journalctl -b | grep -iE 'sddm|qml|dimension'
ls -la /run/current-system/sw/share/sddm/themes
ls -la /run/current-system/sw/share/sddm/themes/dimension
cat /etc/sddm.conf
```

Recommended debugging:

1. Replace QML with a minimal known-good login theme.
2. Confirm SDDM loads `dimension`.
3. Add features back one by one.

## SDDM Login Fails But TTY Works

Symptoms:

- SDDM says authentication failed.
- TTY login works with same user/password.
- Keyboard layout widget displays suspicious values like `?? zz`.

Check:

```sh
localectl status
cat /etc/vconsole.conf
journalctl -u display-manager -b --no-pager
```

Test:

```sh
sudo passwd dimension
```

Use a temporary simple password without characters affected by keyboard layout.

## WSL/Nix ISO Build Crash

If Nix fails with `Bus error`, `Input/output error`, or WSL refuses to restart:

```powershell
wsl.exe --shutdown
```

Then retry:

```powershell
wsl.exe --exec sh -lc 'cd /mnt/e/Projets/dimension-os && /nix/var/nix/profiles/default/bin/nix build --max-jobs 1 --cores 1 .#nixosConfigurations.installer.config.system.build.isoImage'
```

## Flake Cannot See New Files

Symptom:

```text
Path '...' is not tracked by Git
```

Nix flakes using a Git worktree only see tracked or staged files. Stage new files referenced by Nix:

```powershell
git add <file>
```
