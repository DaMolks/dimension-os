# Current Status

Last updated: 2026-04-29

## Summary

Dimension OS is a NixOS flake prototype. The current branch contains Phase 1 installer work and Phase 2 desktop/glass work. Evaluation passes, but VM validation has blockers.

## Validated

These commands passed after the Phase 2 edits:

```powershell
wsl.exe --exec sh -lc 'cd /mnt/e/Projets/dimension-os && /nix/var/nix/profiles/default/bin/nix eval .#nixosConfigurations.desktop-test.config.system.build.toplevel.drvPath'
wsl.exe --exec sh -lc 'cd /mnt/e/Projets/dimension-os && /nix/var/nix/profiles/default/bin/nix flake check --no-build'
```

The installer ISO was built and copied to:

```text
E:\Projets\dimension-os\dimension-os-installer-20260429-phase2.iso
```

Hash:

```text
99122d320604f83b7e2f12dc556bc2216e7a1763878c77c30b408b58d1f14069
```

## Known VM Blockers

### 1. GRUB Theme Error

Observed at boot:

```text
error: (cd0)/EFI/BOOT/grub-theme/theme.txt:8:15 missing separator after property name `progress_bar`.
Press any key to continue...
```

Likely cause: GRUB theme components in `hosts/installer/configuration.nix` use:

```text
progress_bar {
boot_menu {
```

GRUB themes usually expect component blocks:

```text
+ progress_bar {
+ boot_menu {
```

### 2. SDDM Theme Not Loading

Observed login screen is plain/basic, not the Dimension glass QML theme.

Observed facts:

- Session selector shows `Plasma (Wayland)`.
- User/session name is displayed correctly.
- Keyboard layout area shows suspicious `?? zz`.
- The visual style is not the custom glass SDDM design.

Likely causes:

- QML runtime error makes SDDM fall back.
- Theme package not found by SDDM at runtime.
- Qt5Compat/GraphicalEffects import mismatch under the Qt6 greeter.
- `sessionModel`/ComboBox binding or SDDM signal mismatch breaks the theme.

### 3. SDDM Auth Fails, TTY Auth Works

Observed:

- SDDM displays `Echec de l'identification`.
- TTY login with user `dimension` works with the same password.

Likely causes:

- Keyboard layout mismatch in SDDM.
- SDDM fallback greeter in bad layout state.
- PAM issue is possible but less likely than layout/theme failure.

## Immediate Priority

1. Fix GRUB theme syntax and rebuild the ISO.
2. Simplify SDDM `Main.qml` until the custom theme loads reliably.
3. Fix SDDM keyboard layout/auth.
4. Restore glass effects after login reliability is proven.
