# Hub API

The Dimension Hub exposes a local HTTP API for node registration, pairing approval, and WireGuard peer exchange.

**Current status:** local development only. The Hub binds to `127.0.0.1` by default and has no TLS. Do not expose it on LAN until the security model is redesigned.

---

## Configuration

```nix
dimension.hub = {
  enable = true;
  host = "127.0.0.1";   # default
  port = 8787;          # default
  devTokenFile = "/etc/dimension/secrets/hub-dev-token";
};
```

Without `devTokenFile`, the Hub runs in unauthenticated local dev mode and logs a warning. Admin endpoints (approve/reject/pending) always require a token even in dev mode.

---

## Authentication

Protected endpoints require:

```
Authorization: Bearer <token>
```

The token comes from the file at `devTokenFile`. Generate one:

```sh
openssl rand -hex 32 > /etc/dimension/secrets/hub-dev-token
chmod 600 /etc/dimension/secrets/hub-dev-token
chown root:dimension-secrets /etc/dimension/secrets/hub-dev-token
```

---

## Endpoints

### `GET /ping`

Health check. No auth required.

**Response:**
```
200 OK
ok
```

---

### `POST /nodes/ping`

Node heartbeat and self-registration. Protected.

New nodes arrive with `status = "pending"`. Existing nodes update `hostname`, `last_seen`, and `wg_pubkey` while preserving their current status.

**Request body:**
```json
{
  "node_id": "550e8400-e29b-41d4-a716-446655440000",
  "hostname": "my-machine",
  "wg_pubkey": "<base64-wireguard-public-key>",
  "created_at": "2026-04-29T12:00:00+02:00",
  "version": 1
}
```

Only `node_id`, `hostname`, and `wg_pubkey` are stored. Other fields are ignored.

**Response:**
```
200 OK
ok
```

**Errors:**

| Code | Body | Reason |
|------|------|--------|
| 401 | `unauthorized` | Missing or wrong token |
| 400 | `invalid json` | Malformed body |
| 400 | `missing node_id` | `node_id` absent or empty |

---

### `GET /nodes`

List all registered nodes. Protected.

**Response:**
```json
[
  {
    "node_id": "550e8400-e29b-41d4-a716-446655440000",
    "hostname": "my-machine",
    "last_seen": "2026-04-29T12:00:00+02:00",
    "wg_pubkey": "<base64>",
    "status": "approved"
  }
]
```

Status values: `pending`, `approved`, `rejected`.

---

### `GET /nodes/pending`

List nodes awaiting approval. Requires token to be configured on the Hub.

**Response:** same shape as `GET /nodes`, filtered to `status = "pending"`.

---

### `POST /nodes/approve`

Approve a node. Requires token.

**Request body:**
```json
{ "node_id": "550e8400-e29b-41d4-a716-446655440000" }
```

**Response:**
```
200 OK
ok
```

**Errors:**

| Code | Body | Reason |
|------|------|--------|
| 401 | `unauthorized` | Missing token or no token configured |
| 404 | `node not found` | Unknown `node_id` |

---

### `POST /nodes/reject`

Reject a node. Same shape as `/nodes/approve`.

---

### `GET /wireguard/peers`

Approved nodes that have submitted a WireGuard public key. Protected.

**Response:**
```json
[
  {
    "node_id": "550e8400-e29b-41d4-a716-446655440000",
    "hostname": "my-machine",
    "wg_pubkey": "<base64>",
    "last_seen": "2026-04-29T12:00:00+02:00"
  }
]
```

---

### `GET /wireguard/config?node_id=<id>`

Peers visible to a specific node. Excludes the requesting node. Protected.

**Query param:** `node_id` (required)

**Response:**
```json
[
  {
    "node_id": "11111111-1111-1111-1111-111111111111",
    "hostname": "peer-a",
    "wg_pubkey": "<base64>"
  }
]
```

**Errors:**

| Code | Body | Reason |
|------|------|--------|
| 400 | `missing node_id` | No `node_id` param |
| 404 | `node not found` | `node_id` not in registry |

---

## Admin CLI

```sh
dimension-hub-admin list-pending
dimension-hub-admin approve <node_id>
dimension-hub-admin reject <node_id>
```

The admin CLI reads `DIMENSION_HUB_URL` (default `http://127.0.0.1:8787`) and `DIMENSION_HUB_DEV_TOKEN_FILE` (default `/etc/dimension/secrets/hub-dev-token`).

---

## State Files

| Path | Content |
|------|---------|
| `/var/lib/dimension-hub/id` | Hub UUID, generated on first start |
| `/var/lib/dimension-hub/identity.json` | Hub identity (id, hostname, created_at) |
| `/var/lib/dimension-hub/nodes.json` | Node registry |
| `/var/log/dimension-hub/hub.log` | Hub log |

---

## Limitations

- Loopback only. Not safe for LAN exposure without TLS and stronger auth.
- Bearer token is a shared secret, not per-node identity.
- No node deletion endpoint.
- No pagination on `GET /nodes`.
- Peer list is distributed but not yet applied to WireGuard interfaces automatically.
- Pairing is manual approval only, no interactive UI yet.
