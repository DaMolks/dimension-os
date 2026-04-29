# Desktop And Theme

## Stack

- KDE Plasma 6.
- SDDM Wayland.
- Home Manager.
- plasma-manager.
- Kvantum.
- Klassy.
- Papirus-Dark icons.
- Layan cursor theme.
- Inter, Noto, JetBrains Mono.

## Visual Identity

Palette:

- dark navy: `#000F1F`
- accent blue: `#0078D7`
- cold off-white text: `#E8F0F8`

Assets:

- `assets/wallpapers/dimension-desktop-dark.png`
- `assets/wallpapers/dimension-sddm-glass.png`
- `assets/wallpapers/dimension-boot-splash-v2.png`
- `assets/icons/dimension-logo.svg`

## KDE Configuration

System defaults live in:

```text
modules/kde-config/default.nix
```

Per-user Plasma config is declared in:

```text
modules/kde-config/plasma-home.nix
```

This file uses plasma-manager through Home Manager for the main user.

## Panel

The intended panel:

- bottom,
- centered,
- floating,
- translucent,
- app launcher,
- icon tasks,
- spacer,
- system tray,
- clock,
- show desktop.

## Kvantum

Theme files:

```text
modules/theme/kvantum/DimensionGlass.kvconfig
modules/theme/kvantum/DimensionGlass.svg
```

Packaged under:

```text
$out/share/Kvantum/DimensionGlass/
```

System default:

```text
/etc/xdg/Kvantum/kvantum.kvconfig
```

## SDDM

Custom theme module:

```text
modules/sddm/default.nix
```

Expected theme name:

```text
dimension
```

Current VM blocker: the custom SDDM theme does not appear to load. The VM shows a basic/fallback greeter.

Debug with:

```sh
journalctl -u display-manager -b --no-pager
journalctl -b | grep -iE 'sddm|qml|dimension'
ls -la /run/current-system/sw/share/sddm/themes
ls -la /run/current-system/sw/share/sddm/themes/dimension
cat /etc/sddm.conf
```

Recommended fix path:

1. Temporarily replace `Main.qml` with a minimal login theme.
2. Verify the custom theme loads.
3. Add background image.
4. Add fields and login.
5. Add blur/glass effects last.
