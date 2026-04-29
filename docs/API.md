# Hub API

Base URL in current dev mode:

```text
http://127.0.0.1:8787
```

The Hub is not LAN-safe yet. Keep it loopback-only unless the security model is redesigned.

## Authentication

Bearer token from:

```text
dimension.hub.devTokenFile
dimension.node.hubTokenFile
```

Common local path:

```text
/etc/dimension/secrets/hub-dev-token
```

If no token is configured, current dev mode may accept requests. Treat that as local-only development behavior.

## Endpoints

### `GET /ping`

Health check.

### `POST /nodes/ping`

Node heartbeat and registration.

### `GET /nodes`

List all known nodes.

### `GET /nodes/pending`

List pending nodes.

### `POST /nodes/approve`

Approve a node.

### `POST /nodes/reject`

Reject a node.

### `GET /wireguard/peers`

Return approved nodes with WireGuard public keys.

### `GET /wireguard/config?node_id=<id>`

Return peers visible to a specific node.

## Admin CLI

```sh
dimension-hub-admin list-pending
dimension-hub-admin approve <node_id>
dimension-hub-admin reject <node_id>
```
