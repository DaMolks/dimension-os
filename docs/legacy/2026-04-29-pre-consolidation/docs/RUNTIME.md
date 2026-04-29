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
- `dimension-hub` has a manual pairing approval workflow
- `dimension-network` is a real NetworkManager and Avahi foundation
- `dimension-storage` is a real opt-in storage module
- `dimension-storage` can auto-mount a guest SMB share from a remote Hub
- `dimension-remote` is a real opt-in remote module
- `dimension-wireguard` exists as an opt-in interface foundation

Not implemented in the current tree:
- interactive pairing UX
- LAN-safe Hub exposure
- discovery-aware and credentialed storage mounting between machines

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
- `discovered-hub-url.txt`
- `peers.json`

Behavior:
- `id` is created on first start if missing
- `identity.json` is created on first start if missing
- `discovered-hub-url.txt` is written when Hub discovery succeeds
- `peers.json` is refreshed after successful Hub WireGuard config fetches

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
- `nodes.json` stores the Node registry and approval status

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

### `/mnt/dimension-hub`

Purpose:
- default lazy mount point for a remote Hub SMB share

Current state:
- created when `dimension.storage.autoMount.enable = true`
- used as the default `dimension.storage.autoMount.mountPoint`

### WireGuard private key path

Purpose:
- machine-local WireGuard secret material

Current expectation:
- not managed by the repository
- referenced through `dimension.wireguard.privateKeyFile`
- stored manually on the target machine
- can be generated locally with `dimension-wg-keygen`

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
- can auto-discover a Hub over Avahi when `dimension.node.hubDiscovery = true` and `hubUrl` is empty
- optionally reads a bearer token from `dimension.node.hubTokenFile`
- posts `identity.json` to `POST /nodes/ping`
- optionally reads a WireGuard public key from `dimension.node.wgPublicKeyFile`
- fetches `GET /wireguard/config?node_id=...` after each loop when a WireGuard public key is available
- persists fetched peers to `peers.json`
- logs to journald and `/var/log/dimension/node.log`
- loops forever with a fixed 60 second delay

Current limitations:
- no local pairing UX
- no applied WireGuard peer configuration yet
- no structured local state beyond small JSON state files
- no discovery retry or backoff after startup
- no backoff

### `dimension-hub`

Module:
- `modules/hub/default.nix`

Status:
- real minimal service

Behavior:
- runs as system user `dimension-hub`
- binds to `127.0.0.1:8787` by default
- serves `GET /ping`, `GET /nodes`, `GET /nodes/pending`, `GET /wireguard/peers`, `GET /wireguard/config`, `POST /nodes/ping`, `POST /nodes/approve`, and `POST /nodes/reject`
- protects pairing admin endpoints with a bearer token and can also protect the other read/write endpoints when `dimension.hub.devTokenFile` is set
- can advertise `_dimension-hub._tcp` over Avahi when `dimension.hub.advertise = true`
- registers new nodes as `pending`
- only exposes approved nodes through the WireGuard views
- persists registered nodes in `/var/lib/dimension-hub/nodes.json`
- installs a local `dimension-hub-admin` CLI for listing and approving pending nodes
- logs to journald and `/var/log/dimension-hub/hub.log`

Current limitations:
- JSON file persistence only
- no SQLite
- no paging
- no delete endpoint
- manual approval only, no end-user pairing UX
- no LAN-safe exposure
- no TLS
- no direct WireGuard interface application

### `dimension-network`

Module:
- `modules/network/default.nix`

Status:
- real minimal foundation

Behavior:
- enables NetworkManager
- creates `/etc/dimension`
- can enable Avahi with IPv4 mDNS resolution support
- can publish local user services over Avahi
- opens UDP 5353 only when Avahi support is enabled

Current limitations:
- no Dimension-specific LAN trust model
- no network policy beyond Avahi opt-in
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
- can lazily auto-mount `//<hub>/<share>` to `/mnt/dimension-hub` through systemd automount

Current limitations:
- no discovery-aware mount wiring yet
- guest access only, no credential file support
- no approval-aware sharing
- no machine discovery integration

### `dimension-wireguard`

Module:
- `modules/wireguard/default.nix`

Status:
- foundational opt-in module

Behavior:
- declares `networking.wireguard.interfaces.dimension0`
- loads a private key from a file outside the repository
- keeps `peers = []`
- only opens the WireGuard listen port when `openFirewall = true`
- can rely on `dimension-wg-keygen` for local key generation

Current limitations:
- no peer application to `dimension0`
- no peer endpoint or address distribution
- no automatic interface reconciliation after approval
- no automatic host defaults

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
