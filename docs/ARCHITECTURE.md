# Architecture

## Shape

Dimension OS is a NixOS flake. Hosts import shared modules and select an edition. The edition decides which modules are enabled by default.

```text
flake.nix
  inputs: nixpkgs, disko, home-manager, plasma-manager
  hosts: auto-discovered from hosts/*/configuration.nix
  modules: exported under nixosModules

hosts/
  main/
  desktop-test/
  installer/

modules/
  base/
  profiles/
  desktop/
  kde-config/
  theme/
  sddm/
  plymouth/
  hub/
  node/
  wireguard/
  storage/
  remote/
  network/
  apps/
  dimension-settings/
```

## Host Discovery

`flake.nix` reads `hosts/` and creates a NixOS configuration for every directory that contains `configuration.nix`.

This means new hosts do not need manual registration in `flake.nix`.

## Composition

The main composition layer is:

```text
modules/profiles/default.nix
```

It reads:

```nix
dimension.edition
```

and sets defaults for:

- `dimension.apps.enable`
- `dimension.desktop.enable`
- `dimension.kde.enable`
- `dimension.theme.enable`
- `dimension.sddm.enable`
- `dimension.plymouth.enable`
- `dimension.hub.enable`
- `dimension.node.enable`
- `dimension.storage.enable`
- `dimension.remote.enable`
- `dimension.network.enable`
- `dimension.wireguard.enable`

## Editions

Valid editions:

- `desktop`
- `laptop`
- `home-theatre`
- `server`
- `server-headless`
- `print-station`
- `gaming`
- `workstation`

Only `server-headless` disables the desktop by default.

## Runtime Direction

The long-term architecture is:

- each machine runs a Dimension Node,
- one or more machines can run a Dimension Hub,
- Hub approves nodes and distributes state,
- WireGuard connects approved machines,
- storage and remote access are opt-in modules,
- KDE/Dimension desktop gives the user-facing layer.

The current implementation is still local/dev oriented.
