# Dimension - Security

This document captures the current security posture and the guardrails for
future work.

---

## Principles

### Local-first by default

Development services should stay local unless a network exposure step is
explicitly designed, documented, and validated.

### No secrets in Git

Never store:
- passwords
- bearer tokens
- private keys
- WireGuard keys
- pairing secrets

### Firewall closed by default

Ports must only be opened through explicit opt-in options such as
`openFirewall = true`.

### Least privilege

Dedicated service users and narrow writable paths are preferred for long-lived
 services.

### Honest docs

Security docs must describe the code that exists now, not the architecture we
intend to build later.

---

## Current State

### Hub

- `dimension-hub` runs as system user `dimension-hub`
- default bind is `127.0.0.1:8787`
- optional bearer token is read from `dimension.hub.devTokenFile`
- writable paths are limited to:
- `/var/lib/dimension-hub`
- `/var/log/dimension-hub`
- `/etc/dimension/hub`

Current risks:
- loopback HTTP only, no TLS
- shared bearer token model only
- manual approval only, no cryptographic machine identity

### Node

- `dimension-node` runs as system user `dimension-node`
- optional bearer token is read from `dimension.node.hubTokenFile`
- writable paths are limited to:
- `/var/lib/dimension/node`
- `/var/log/dimension`

Current risks:
- no local pairing UX
- no strong identity model
- no applied WireGuard peer configuration
- no retry backoff

### Storage

- Samba and wsdd are opt-in
- SFTP is opt-in
- SMB ports are closed unless `dimension.storage.samba.openFirewall = true`

Current risks:
- no cross-machine trust model
- no approval-aware share policy

### Remote

- Sunshine is opt-in
- Sunshine firewall opening is opt-in
- Wake-on-LAN is opt-in

Current risks:
- no Dimension-level remote access policy
- no onboarding or approval flow

### Network

- `dimension-network` is still a placeholder
- no Avahi integration
- WireGuard exists as a local interface foundation only

### WireGuard

- `dimension.wireguard.enable` is opt-in
- the private key is loaded from a local file path
- `dimension-wg-keygen` generates keys locally on the machine
- `openFirewall` stays `false` by default
- no peers are configured by default

Current risks:
- no automated key lifecycle
- approval exists only at the Hub registry layer
- no applied interface reconciliation from Hub-distributed peer data

---

## Systemd Hardening In Use

Current Dimension-managed services use a hardened baseline such as:
- `NoNewPrivileges=true`
- `PrivateTmp=true`
- `ProtectSystem=strict`
- `ProtectHome=true`
- `LockPersonality=true`
- `MemoryDenyWriteExecute=true`
- `SystemCallArchitectures=native`

`dimension-node` and `dimension-hub` also restrict address families to:
- `AF_UNIX`
- `AF_INET`
- `AF_INET6`

---

## Checklist Before LAN or VPN Exposure

Before exposing any Dimension service beyond loopback:

- [ ] authentication model documented
- [ ] transport security documented
- [ ] ports documented
- [ ] firewall rules reviewed
- [ ] secrets flow documented
- [ ] service users reviewed
- [ ] writable paths reviewed
- [ ] protocol tested
- [ ] rollback path documented
- [ ] logs checked for secret leakage

---

## Immediate Security Priorities

- document peer lifecycle
- document approval and rejection lifecycle
- move away from a shared local dev token model for multi-machine use
- add test coverage for exposed services and opt-in firewall paths
