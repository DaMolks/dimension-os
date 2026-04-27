# Dimension - WireGuard

This document describes the current WireGuard baseline in the repository.

## Current State

The repository ships an opt-in WireGuard module:
- module: `modules/wireguard/default.nix`
- interface name: `dimension0`
- firewall closed by default
- no peers configured by default

This is a local machine foundation only.
The current Hub / Node contract also supports a minimal public-key flow:
- `dimension-node` can send `wg_pubkey` in `POST /nodes/ping`
- `dimension-hub` stores that key in `nodes.json`
- `GET /wireguard/peers` exposes the known public keys back as a read-only view

Peer orchestration and Hub-driven distribution are not implemented yet.

## Enable on a Host

Example:

```nix
dimension.wireguard = {
  enable = true;
  privateKeyFile = "/etc/dimension/secrets/wg-private-key";
  address = "10.100.0.10/24";
  openFirewall = true;
};
```

Required fields:
- `privateKeyFile`
- `address`

Optional fields:
- `listenPort` defaults to `51820`
- `openFirewall` defaults to `false`

## Key Generation

Dimension now ships a helper:

```sh
sudo dimension-wg-keygen
```

Default output:
- private key: `/etc/dimension/secrets/wg-private-key`
- public key: `/etc/dimension/secrets/wg-public-key`

You can also choose a different target directory:

```sh
sudo dimension-wg-keygen /etc/dimension/my-vpn
```

The helper:
- creates the target directory with mode `0700`
- creates the private key with mode `0600`
- creates the public key with mode `0644`
- refuses to overwrite existing key files

## Key Handling Rules

- never store the private key in Git
- generate the private key on the machine
- treat the public key as shareable machine identity material
- keep the private key readable only by root
- back up the private key through your secret management process, not through the repository

## What Is Still Missing

- peer configuration generation
- peer distribution
- Hub-managed approval workflow
- key rotation workflow
- automatic host enrollment
- tests covering multi-machine VPN behavior
