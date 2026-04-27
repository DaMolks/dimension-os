# Dimension - Runtime

This document records the runtime conventions that are true for the repository
today.

It is intentionally conservative: if code and docs disagree, the code wins and
this document must be updated.

---

## Current Summary

Implemented now:
- `dimension-node` is a real minimal agent
- `dimension-hub` is a real minimal local HTTP service
- `dimension-storage` is a real opt-in storage module
- `dimension-remote` is a real opt-in remote module
- `dimension-network` is still a placeholder

Not implemented in the current tree:
- WireGuard module
- pairing approval workflow
- LAN-safe Hub exposure
- automatic storage mounting between machines

---

## Filesystem Paths

### `/etc/dimension`

Purpose:
- root for local Dimension configuration

Current state:
- created by `dimension.network.enable`

Notes:
- no shared schema yet
- no common config file yet

### `/var/lib/dimension/node`

Purpose:
- persistent local state for `dimension-node`

Current files:
- `agent.sh`
- `id`
- `identity.json`

Behavior:
- `id` is created on first start if missing
- `identity.json` is created on first start if missing

### `/var/log/dimension`

Purpose:
- text logs for `dimension-node`

Current files:
- `node.log`

### `/var/lib/dimension-hub`

Purpose:
- persistent local state for `dimension-hub`

Current files:
- `hub.sh`
- `id`
- `identity.json`
- `nodes.json`

Behavior:
- `id` is created on first start if missing
- `identity.json` is created on first start if missing
- `nodes.json` stores the Node registry

### `/var/log/dimension-hub`

Purpose:
- text logs for `dimension-hub`

Current files:
- `hub.log`

### `/etc/dimension/hub`

Purpose:
- local Hub configuration directory

Current state:
- created when `dimension.hub.enable = true`

### `/etc/dimension/storage`

Purpose:
- reserved local storage configuration root

Current state:
- created when `dimension.storage.enable = true`

### `/etc/dimension/remote`

Purpose:
- reserved local remote configuration root

Current state:
- created when `dimension.remote.enable = true`

### `/mnt/dimension`

Purpose:
- shared storage root

Current state:
- created by the storage module
- exported through Samba when `dimension.storage.samba.enable = true`

---

## Services

### `dimension-node`

Module:
- `modules/node/default.nix`

Status:
- real minimal service

Behavior:
- runs as system user `dimension-node`
- creates local identity if missing
- optionally reads a bearer token from `dimension.node.hubTokenFile`
- posts `identity.json` to `POST /nodes/ping`
- logs to journald and `/var/log/dimension/node.log`
- loops forever with a fixed 60 second delay

Current limitations:
- no pairing
- no WireGuard
- no structured local state beyond identity files
- no LAN discovery
- no backoff

### `dimension-hub`

Module:
- `modules/hub/default.nix`

Status:
- real minimal service

Behavior:
- runs as system user `dimension-hub`
- binds to `127.0.0.1:8787` by default
- serves `GET /ping`, `GET /nodes`, and `POST /nodes/ping`
- optionally protects `GET /nodes` and `POST /nodes/ping` with a bearer token
- persists registered nodes in `/var/lib/dimension-hub/nodes.json`
- logs to journald and `/var/log/dimension-hub/hub.log`

Current limitations:
- JSON file persistence only
- no SQLite
- no paging
- no delete endpoint
- no pairing
- no LAN-safe exposure
- no TLS

### `dimension-network`

Module:
- `modules/network/default.nix`

Status:
- placeholder

Behavior:
- enables NetworkManager
- creates `/etc/dimension`
- runs a hardened `oneshot` service that executes `true`

Current limitations:
- no mDNS discovery
- no Avahi integration
- no WireGuard

### `dimension-storage`

Module:
- `modules/storage/default.nix`

Status:
- real opt-in module

Behavior:
- creates `/etc/dimension/storage`
- creates `/mnt/dimension`
- can enable Samba with wsdd
- can enable SFTP through OpenSSH

Current limitations:
- no automatic mount strategy
- no approval-aware sharing
- no machine discovery integration

### `dimension-remote`

Module:
- `modules/remote/default.nix`

Status:
- real opt-in module

Behavior:
- creates `/etc/dimension/remote`
- can enable Sunshine
- can enable Wake-on-LAN on one interface or all detected Ethernet interfaces

Current limitations:
- no Dimension session model
- no login-manager integration
- no onboarding flow for WOL and remote access

---

## Desktop Runtime Defaults

Current desktop-facing pieces:
- `dimension-search` launches KRunner
- Baloo also indexes `/mnt/dimension`
- a default Plasma panel is provided through `/etc/xdg`
- a system wallpaper and color scheme are shipped
- SDDM uses a branded background

Still missing:
- Dimension Settings application
- widgets
- custom shell behavior
- Dimension-specific search providers
