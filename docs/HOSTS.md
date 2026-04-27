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

## Generated Hosts

The repository also ships `dimension-install`, a small CLI helper that can
generate `hosts/<name>/configuration.nix` templates.

Current limitation:
- generated hosts are not added to `flake.nix` automatically yet
