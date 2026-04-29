# Security

## Non-Negotiables

- No secrets in Git.
- No WireGuard private keys in Git.
- No bearer tokens in Git.
- Hub stays loopback-only until LAN/VPN exposure is designed.
- Prefer explicit opt-in for network services.

## Secret Paths

```text
/etc/dimension/secrets/hub-dev-token
/etc/dimension/secrets/wg-private-key
```

Recommended ownership:

```text
root:dimension-secrets
```

Recommended permissions:

```text
0750 /etc/dimension/secrets
0640 token files when shared with service users
0600 private keys when only root should read
```

## Current Exposure

- Firewall is enabled by default.
- SSH is disabled in `modules/base`.
- Hub defaults to `127.0.0.1`.
- WireGuard is disabled by default.
- Storage and remote services are option-driven.

## Before LAN Exposure

Do not expose Hub to LAN until:

- auth is mandatory,
- TLS or a trusted local tunnel exists,
- pairing identity is defined,
- audit logs are clear,
- rejection/revocation path is tested.

## Before Committing

Run:

```powershell
git status --short
```

Inspect for:

- `.iso`
- `.qcow2`
- secrets,
- `.claude/`,
- local logs,
- generated `/result`.
