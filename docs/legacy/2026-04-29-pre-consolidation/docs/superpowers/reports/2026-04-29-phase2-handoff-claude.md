# Dimension OS Phase 2 - Handoff Claude

Date: 2026-04-29
Auteur: Codex
But: archiver l'etat Phase 2 et donner a Claude un point de reprise court.

## Etat general

Phase 2 "Bureau Apple-like Glass/Blur" a ete implementee partiellement et compilee en ISO.

ISO produite:

- `E:\Projets\dimension-os\dimension-os-installer-20260429-phase2.iso`
- Taille: `1461977088` bytes
- SHA256: `99122d320604f83b7e2f12dc556bc2216e7a1763878c77c30b408b58d1f14069`

Validations effectuees avant build ISO:

- `nix eval .#nixosConfigurations.desktop-test.config.system.build.toplevel.drvPath` passe.
- `nix flake check --no-build` passe.
- L'ISO installateur build apres un `wsl --shutdown` suite a un crash WSL/Nix transitoire.

Important: les tests VM montrent encore des regressions critiques a corriger avant validation Phase 2.

## Changements principaux

### Flake et Home Manager

- `flake.nix`: ajout de `home-manager` et `plasma-manager`.
- `flake.nix`: ajout de `home-manager.nixosModules.home-manager` aux modules globaux.
- `flake.nix`: `specialArgs` expose `inputs`, `home-manager`, `plasma-manager`.
- `flake.lock`: pins ajoutes pour `home-manager` et `plasma-manager`.

### SDDM user display

- `modules/base/default.nix`: suppression de `description = "Dimension main user";` dans `users.users.${cfg.mainUser}`.
- Effet observe: SDDM affiche maintenant le vrai nom de session/utilisateur au lieu de "Dimension main user".

### Assets

Assets crees:

- `assets/wallpapers/dimension-desktop-dark.png` - 2560x1440
- `assets/wallpapers/dimension-sddm-glass.png` - 1920x1080
- `assets/wallpapers/dimension-boot-splash-v2.png` - 1920x1080
- `assets/icons/dimension-logo.svg`

### Theme KDE / Kvantum / Klassy

- `modules/theme/kvantum/DimensionGlass.kvconfig`
- `modules/theme/kvantum/DimensionGlass.svg`
- `modules/theme/default.nix` package le theme Kvantum dans `$out/share/Kvantum/DimensionGlass/`.
- Ajouts packages: Papirus, Layan cursors, Kvantum, Klassy, Inter, Noto, Noto CJK, JetBrains Mono.
- Bug corrige apres test VM: `noto-fonts-cjk` n'existe pas dans ce nixpkgs. Remplace par `noto-fonts-cjk-sans` avec fallback.

### KDE declaratif

- Nouveau module: `modules/kde-config/plasma-home.nix`.
- Utilise `plasma-manager` via Home Manager pour:
  - panel flottant bas centre,
  - wallpaper Dimension,
  - theme Papirus-Dark,
  - curseur Layan,
  - effets KWin blur/translucency,
  - suppression ksplash via `ksplashrc`.
- `modules/kde-config/default.nix`:
  - suppression de l'ancien seed `/etc/skel` pour panel Plasma,
  - ajout defaults KDE dans `/etc/xdg/kdeglobals`,
  - ajout `/etc/xdg/kwinrc`,
  - ajout `/etc/xdg/ksplashrc`,
  - ajout profil Konsole `Dimension`,
  - ajout script KWin local `dimension-forceblur`.

### SDDM custom theme

- `modules/sddm/default.nix` a ete reecrit avec un QML glassmorphism:
  - fond `dimension-sddm-glass.png`,
  - carte login blur/glass,
  - icones username/password,
  - animations focus/hover/fade,
  - selecteur de session.

Attention: en VM, le theme custom ne semble pas etre celui qui s'affiche. Voir bugs ouverts.

### Plymouth

- `modules/plymouth/default.nix`: utilise maintenant `assets/wallpapers/dimension-boot-splash-v2.png`.

## Bugs observes en VM

### 1. Erreur GRUB au boot

Screenshot 1:

```text
error: (cd0)/EFI/BOOT/grub-theme/theme.txt:8:15 missing separator after property name `progress_bar`.
Press any key to continue...
```

Contexte probable:

- Le fichier `hosts/installer/configuration.nix` genere un theme GRUB custom.
- Dans `theme.txt`, les blocs `progress_bar { ... }` et probablement `boot_menu { ... }` sont declares sans prefixe composant GRUB.
- La syntaxe GRUB theme attend normalement des composants sous forme:

```text
+ progress_bar {
  ...
}

+ boot_menu {
  ...
}
```

Action recommandee:

1. Modifier le heredoc `theme.txt` dans `hosts/installer/configuration.nix`.
2. Remplacer `progress_bar {` par `+ progress_bar {`.
3. Remplacer `boot_menu {` par `+ boot_menu {`.
4. Rebuild ISO et tester boot.

Fallback si urgent:

- Desactiver temporairement le `isoImage.grubTheme` custom pour revenir au theme NixOS par defaut.

### 2. Ecran de login SDDM pas beau / theme custom absent

Screenshot 2:

- L'ecran affiche une UI SDDM basique, pas le theme QML Dimension glass cree.
- La session `Plasma (Wayland)` apparait bien.
- Le layout clavier affiche `?? zz`, ce qui est suspect.
- L'utilisateur/session apparait bien (`DIMENSION`), donc la correction GECOS fonctionne.

Hypotheses:

- Le theme SDDM Dimension ne se charge pas et SDDM tombe sur un fallback.
- Le QML custom peut echouer au runtime dans le greeter Qt6.
- Points suspects dans `modules/sddm/default.nix`:
  - import `Qt5Compat.GraphicalEffects` sous greeter Plasma 6/Qt6,
  - usage de `Controls.ComboBox` avec `sessionModel` directement,
  - `onLoginSucceeded` peut ne pas exister comme signal SDDM,
  - `ShaderEffectSource.sourceRect` avec `mapToItem(...)` inline peut etre fragile,
  - `metadata.desktop`/theme package ou override `sddmPackage` a verifier.

Actions recommandees:

1. Dans la VM, ouvrir une TTY et lire:

```bash
journalctl -u display-manager -b --no-pager
journalctl -b | grep -iE 'sddm|qml|dimension'
ls -la /run/current-system/sw/share/sddm/themes
ls -la /run/current-system/sw/share/sddm/themes/dimension
cat /etc/sddm.conf
```

2. Simplifier temporairement `Main.qml` au minimum:
   - fond image,
   - champ user,
   - champ password,
   - bouton login,
   - aucun blur/Canvas/ComboBox.
3. Une fois le theme charge, rajouter les effets un par un.

### 3. SDDM refuse la connexion, mais login console fonctionne

Screenshot 2:

```text
Echec de l'identification
```

Screenshot 3:

- Login TTY avec `dimension` fonctionne.
- Meme utilisateur et mot de passe acceptes en ligne de commande.

Hypotheses prioritaires:

1. Probleme de layout clavier dans SDDM:
   - Screenshot montre `Disposition ?? zz`.
   - Le mot de passe peut etre saisi differemment dans SDDM que dans TTY.
   - A verifier en testant un mot de passe simple temporaire, ex. `testtest`.

2. Theme/fallback SDDM ou greeter en mauvais etat:
   - Comme le theme custom ne semble pas charge, le greeter peut etre dans un fallback incoherent.

3. PAM/session:
   - Moins probable si l'echec est immediatement "identification", mais verifier les logs.

Actions recommandees:

```bash
journalctl -u display-manager -b --no-pager
localectl status
cat /etc/vconsole.conf
cat /etc/X11/xorg.conf.d/*keyboard* 2>/dev/null
```

Tester aussi:

```bash
sudo passwd dimension
# mettre temporairement un mot de passe sans caracteres ambigus
```

Puis ressayer SDDM.

## Commandes utiles de reprise

Depuis Windows/PowerShell:

```powershell
wsl.exe --exec sh -lc 'cd /mnt/e/Projets/dimension-os && /nix/var/nix/profiles/default/bin/nix flake check --no-build'
wsl.exe --exec sh -lc 'cd /mnt/e/Projets/dimension-os && /nix/var/nix/profiles/default/bin/nix eval .#nixosConfigurations.desktop-test.config.system.build.toplevel.drvPath'
wsl.exe --exec sh -lc 'cd /mnt/e/Projets/dimension-os && /nix/var/nix/profiles/default/bin/nix build --max-jobs 1 --cores 1 .#nixosConfigurations.installer.config.system.build.isoImage'
wsl.exe --exec sh -lc 'cd /mnt/e/Projets/dimension-os && cp -f result/iso/dimension-os-installer.iso dimension-os-installer-20260429-phase2.iso && sha256sum dimension-os-installer-20260429-phase2.iso'
```

Si WSL/Nix crash pendant la construction ISO:

```powershell
wsl.exe --shutdown
```

Puis relancer le build en `--max-jobs 1 --cores 1`.

## Etat Git au moment du handoff

Fichiers Phase 2 ajoutes/stages par Codex pour que Nix flakes les voie:

- `assets/icons/dimension-logo.svg`
- `assets/wallpapers/dimension-boot-splash-v2.png`
- `assets/wallpapers/dimension-desktop-dark.png`
- `assets/wallpapers/dimension-sddm-glass.png`
- `modules/kde-config/plasma-home.nix`
- `modules/theme/kvantum/DimensionGlass.kvconfig`
- `modules/theme/kvantum/DimensionGlass.svg`

Fichiers modifies importants:

- `flake.nix`
- `flake.lock`
- `modules/base/default.nix`
- `modules/kde-config/default.nix`
- `modules/plymouth/default.nix`
- `modules/sddm/default.nix`
- `modules/theme/default.nix`
- `hosts/installer/configuration.nix` et `modules/base/default.nix` contiennent aussi des changements Phase 1/installer deja presents dans le worktree avant ce handoff. Ne pas les revert sans verification.

Artefacts non sources presents a ignorer ou archiver separement:

- `dimension-os-installer-20260429-phase2.iso`
- `dimension-os-installer-20260429-sddm-fix.iso`
- `dimension-os-installer-20260429-sddm-writable-fix.iso`
- `check-build.sh`
- `watchdog.sh`
- `.claude/`

## Priorite de correction proposee

1. Fix GRUB theme syntax dans `hosts/installer/configuration.nix`, rebuild ISO, verifier que le boot n'affiche plus l'erreur.
2. Diagnostiquer pourquoi SDDM n'utilise pas le theme Dimension:
   - logs `display-manager`,
   - presence du theme dans `/run/current-system/sw/share/sddm/themes/dimension`,
   - simplification de `Main.qml`.
3. Corriger le login SDDM:
   - verifier layout clavier,
   - tester mot de passe simple,
   - verifier logs PAM/SDDM.
4. Ensuite seulement reprendre le polish glassmorphism.
