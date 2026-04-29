# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Dimension OS is a NixOS flake for a KDE Plasma 6 multi-machine personal operating system. Development happens on Windows; all Nix commands must run from WSL2 at the path `/mnt/e/Projets/dimension-os`.

## Validation

```sh
# From WSL2 — validates flake evaluation without building
nix flake check --no-build

# Build a specific host
nix build .#nixosConfigurations.desktop-test.config.system.build.toplevel

# Build the installer ISO
nix build .#nixosConfigurations.installer.config.system.build.isoImage
```

Secrets (tokens, WireGuard private keys) must **never** be committed to Git. They live in `/etc/dimension/secrets/` on the target machine, outside the flake.

## Module system

All NixOS modules live in `modules/` and are re-exported via `flake.nix` as `nixosModules`. Every module exposes its options under `config.dimension.*`.

**`modules/profiles/`** is the main composition layer. It reads `dimension.edition` and sets sensible defaults for all other modules via `lib.mkDefault`. Host configs import `modules/profiles` and then override specific options.

Edition values: `desktop`, `laptop`, `home-theatre`, `server`, `server-headless`, `print-station`, `gaming`, `workstation`. The default is `server-headless` (no desktop).

Each module follows the same pattern:
```nix
options.dimension.<name>.enable = lib.mkEnableOption "...";
config = lib.mkIf cfg.enable { ... };
```

## Runtime services

Two systemd services implement the Hub↔Node protocol:

**Hub** (`modules/hub/`) — Python HTTP server on `127.0.0.1:8787` (default). Persists node registry to `/var/lib/dimension-hub/nodes.json`. Runs as `dimension-hub` system user. New nodes arrive as `pending` and must be manually approved.

**Node** (`modules/node/`) — Shell agent that posts machine identity to the Hub every 60s and fetches WireGuard peer lists. Runs as `dimension-node` system user. State lives in `/var/lib/dimension/node/`.

**Hub admin CLI** (installed when Hub is enabled):
```sh
dimension-hub-admin list-pending
dimension-hub-admin approve <node_id>
dimension-hub-admin reject <node_id>
```

**WireGuard keygen helper** (when wireguard module is enabled):
```sh
dimension-wg-keygen   # generates private/public key pair locally
```

## Hub API summary

Base URL: `http://127.0.0.1:8787` — loopback only, no TLS, not LAN-safe in current state.

| Endpoint | Auth | Description |
|---|---|---|
| `GET /ping` | none | health check |
| `POST /nodes/ping` | token | node registers/updates itself |
| `GET /nodes` | token | list all nodes |
| `GET /nodes/pending` | token (required) | list pending nodes |
| `POST /nodes/approve` | token (required) | approve a node |
| `POST /nodes/reject` | token (required) | reject a node |
| `GET /wireguard/peers` | token | approved nodes with WireGuard keys |
| `GET /wireguard/config?node_id=<id>` | token | peers visible to a specific node |

Authentication is a Bearer token read from `devTokenFile`. Without it, the Hub logs a warning and accepts all requests (loopback dev only).

## Key secrets paths (never in Git)

| Path | Purpose |
|---|---|
| `/etc/dimension/secrets/hub-dev-token` | Shared token for Hub↔Node auth |
| `/etc/dimension/secrets/wg-private-key` | WireGuard private key |

The `dimension-secrets` group grants read access to both `dimension-hub` and `dimension-node` service users.

## Hosts

| Host | Edition | Purpose |
|---|---|---|
| `main` | `server-headless` | local Hub+Node dev machine |
| `desktop-test` | (see config) | visual KDE validation |
| `installer` | — | graphical live ISO |

## Current state and roadmap

Phases 1–3 (flake structure, desktop, editions) are complete. Phase 6 (stabilization) is the current priority. Phases 7–11 (network backbone, Hub/Node evolution, shared storage, search/shell, release readiness) are planned.

The `modules/network/` module is still a placeholder. WireGuard is implemented but disabled by default — VPN subnet allocation and peer application are not yet wired up.

## Project language

Specification documents (`SPEC.md`, `ARCHITECTURE.md`, inline comments in hosts/) are in French. Code, NixOS option descriptions, and log messages are in English.
