# Dimension - Hosts

This document describes the hosts that are currently declared in the flake.

They are generic validation hosts, not hardware-specific machine definitions.

---

## `main`

File:
- `hosts/main/configuration.nix`

Role:
- generic local development host
- default edition is `server-headless`
- used to validate the minimal Hub / Node loopback setup

Current specifics:
- explicitly enables the Hub on `127.0.0.1:8787`
- points the Node to that local Hub
- expects a local development token at `/etc/dimension/secrets/hub-dev-token`

Notes:
- this host is intentionally not the visual desktop validation target
- it keeps the focus on local runtime behavior

---

## `desktop-test`

File:
- `hosts/desktop-test/configuration.nix`

Role:
- generic desktop validation host
- used to check KDE, panel, search, icons, wallpaper, and theme behavior

Current specifics:
- sets `dimension.edition = "desktop"`
- pulls its behavior from the shared edition-driven modules

Notes:
- this host is for UX validation, not for Hub / Node local development

---

## `installer`

File:
- `hosts/installer/configuration.nix`

Role:
- graphical live ISO target
- used to build a Plasma 6 installer image with Dimension branding

Current specifics:
- imports the official NixOS Calamares Plasma 6 installer module
- keeps Dimension apps, KDE defaults, and theme modules through the shared profile stack
- explicitly disables runtime services that are not needed on the live ISO:
- `dimension.desktop`
- `dimension.hub`
- `dimension.node`
- `dimension.remote`
- `dimension.storage`
- `dimension.wireguard`

Notes:
- this host is intended for ISO builds, not for installed machines

## Generated Hosts

The repository also ships `dimension-install`, a small CLI helper that can
generate `hosts/<name>/configuration.nix` templates.

Current limitation:
- generated hosts are not added to `flake.nix` automatically yet
