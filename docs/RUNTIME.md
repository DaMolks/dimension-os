# Runtime

## Users

Main user:

```nix
dimension.mainUser = "dimension";
```

Service users:

- `dimension-hub`
- `dimension-node`

Shared secrets group used on the dev host:

```text
dimension-secrets
```

## Important Paths

```text
/etc/dimension
/etc/dimension/secrets
/var/lib/dimension/node
/var/lib/dimension-hub
/var/log/dimension
/var/log/dimension-hub
/mnt/dimension
/mnt/dimension-hub
```

## Hub

Service:

```text
dimension-hub
```

Default URL:

```text
http://127.0.0.1:8787
```

State:

```text
/var/lib/dimension-hub/nodes.json
```

Admin commands:

```sh
dimension-hub-admin list-pending
dimension-hub-admin approve <node_id>
dimension-hub-admin reject <node_id>
```

## Node

Service:

```text
dimension-node
```

State:

```text
/var/lib/dimension/node/
```

The node posts identity to the Hub and fetches WireGuard peer information.

## WireGuard

Private key path convention:

```text
/etc/dimension/secrets/wg-private-key
```

Helper:

```sh
dimension-wg-keygen
```

WireGuard is disabled by default and not yet fully Hub-managed.

## Storage

Storage module can enable:

- Samba,
- wsdd,
- SFTP.

## Remote

Remote module can enable:

- Sunshine,
- Wake-on-LAN helper.
