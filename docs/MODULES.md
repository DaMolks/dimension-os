# Module Catalog

## `modules/base`

Shared defaults:

- locale `fr_FR.UTF-8`
- timezone `Europe/Paris`
- console keymap `fr`
- main user option: `dimension.mainUser`
- base packages
- Nix flakes enabled
- firewall enabled
- SSH disabled by default
- helper: `dimension-install`
- helper: `dimension-wg-keygen`

## `modules/profiles`

Edition composition. Selects defaults from `dimension.edition`.

## `modules/desktop`

Plasma desktop base:

- X server enabled for Plasma stack.
- Plasma 6 enabled.
- SDDM enabled with Wayland.
- NetworkManager.
- PipeWire.
- Bluetooth.
- Firefox, Konsole, Dolphin, Ark, Spectacle.

## `modules/kde-config`

KDE defaults and declarative user config:

- imports `plasma-home.nix`
- system KDE defaults under `/etc/xdg`
- KWin blur/contrast config
- Klassy window decoration config
- ksplash disabled
- Konsole Dimension profile
- local KWin script `dimension-forceblur`

## `modules/kde-config/plasma-home.nix`

Home Manager + plasma-manager config for the main user:

- floating bottom panel,
- pinned launchers,
- wallpaper,
- color scheme,
- icon and cursor themes,
- KWin effects,
- titlebar buttons,
- ksplash disabled per user.

## `modules/theme`

Visual foundation:

- Dimension KDE color scheme,
- Papirus icons,
- Layan cursor theme,
- Inter/Noto/JetBrains Mono fonts,
- Kvantum engine,
- Klassy,
- DimensionGlass Kvantum theme.

## `modules/sddm`

Packages a custom SDDM theme named `dimension`.

Current blocker: VM shows fallback/basic SDDM instead of this theme. See [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

## `modules/plymouth`

Dimension boot splash using:

```text
assets/wallpapers/dimension-boot-splash-v2.png
```

## `modules/hub`

Local HTTP Hub prototype:

- default host `127.0.0.1`
- default port `8787`
- state in `/var/lib/dimension-hub`
- optional bearer token from `devTokenFile`
- node approval commands.

## `modules/node`

Local Node prototype:

- posts identity to Hub,
- fetches WireGuard peers,
- persists state under `/var/lib/dimension/node`,
- runs as `dimension-node`.

## `modules/wireguard`

Foundational WireGuard interface module. Disabled by default.

It does not yet implement full Hub-managed peer application.

## `modules/storage`

Opt-in storage features:

- Samba,
- wsdd,
- SFTP via OpenSSH,
- mount roots under `/mnt/dimension` and `/mnt/dimension-hub`.

## `modules/remote`

Opt-in remote features:

- Sunshine,
- Wake-on-LAN helper service.

## `modules/network`

Network foundation:

- NetworkManager,
- optional Avahi/mDNS.

Still thin and expected to evolve in the network backbone phase.

## `modules/apps`

Dimension desktop entries:

- Dimension Search,
- Dimension Hub,
- Dimension Settings placeholder.

## `modules/dimension-settings`

Prototype Dimension Settings application. Enabled by default for `desktop` and `workstation`.
