# WireGuard

Dimension OS includes a foundational WireGuard module. It is **disabled by default** on all editions. The Hub-managed peer application is not yet implemented — the current module sets up the interface and key infrastructure only.

---

## Key Generation

On the target machine, run:

```sh
dimension-wg-keygen
```

By default this writes to `/etc/dimension/secrets/`:

```text
/etc/dimension/secrets/wg-private-key   (0600, root only)
/etc/dimension/secrets/wg-public-key    (0644)
```

To write to a custom directory:

```sh
dimension-wg-keygen /path/to/dir
```

The command refuses to overwrite existing keys. Generate once, keep the private key on the machine only. The public key can be shared with the Hub.

---

## Enabling WireGuard On A Host

```nix
dimension.wireguard = {
  enable = true;
  privateKeyFile = "/etc/dimension/secrets/wg-private-key";
  address = "10.100.0.1/24";
  listenPort = 51820;   # default, can be omitted
  openFirewall = true;  # required to accept inbound connections
};
```

This creates a `dimension0` WireGuard interface at the given address. No peers are added automatically yet.

### Address Convention

```text
10.100.0.0/24   Dimension VPN subnet
10.100.0.1      Hub (server)
10.100.0.2+     Nodes (clients)
```

Pick a fixed address for each machine. The subnet is private and not exposed beyond the WireGuard mesh.

---

## Node Integration

When WireGuard is enabled on a node, register the public key with the Node agent so it is sent to the Hub on heartbeat:

```nix
dimension.node = {
  hubUrl = "http://<hub-ip>:8787";
  hubTokenFile = "/etc/dimension/secrets/hub-dev-token";
  wgPublicKeyFile = "/etc/dimension/secrets/wg-public-key";
};
```

The Hub stores the public key in `nodes.json` and exposes it via `GET /wireguard/config?node_id=<id>`. The Node fetches this list and persists it locally at `/var/lib/dimension/node/peers.json`.

**Peer application is not yet automated.** The peer list is fetched but not written to the WireGuard interface. This is the next engineering step.

---

## Hub Integration

The Hub reads public keys from the node registry and exposes two endpoints:

- `GET /wireguard/peers` — all approved nodes with a public key.
- `GET /wireguard/config?node_id=<id>` — peers visible to a specific node (excludes the requesting node itself).

Only nodes with `status = "approved"` appear in these responses.

---

## Firewall

`openFirewall = true` opens the listen port on all interfaces by default. For a more restricted setup, open only the LAN interface:

```nix
networking.firewall.allowedUDPPorts = [ 51820 ];
```

Do not expose the WireGuard port on untrusted interfaces until the peer exchange and identity model are finalised.

---

## Current Limitations

- Peer list is fetched from Hub but not applied to the interface.
- No automatic key rotation.
- No revocation path.
- Subnet addressing is manual (no allocation from Hub).
- No Hub-managed peer config push.

These gaps are addressed in Phase 3 (Hub/Node Production Direction).

---

## Secrets Policy

- Private key: never in Git, never logged, `0600`.
- Public key: safe to share with the Hub, `0644`.
- Hub token: never in Git, used only on the loopback Hub endpoint.

Secret directory permissions:

```text
d /etc/dimension/secrets  0750  root  dimension-secrets
```

Service users `dimension-hub` and `dimension-node` are members of `dimension-secrets` on the `main` dev host.
