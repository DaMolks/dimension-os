# Dimension - Test local Node vers Hub

Ce document decrit le test de developpement local entre `dimension-node` et
`dimension-hub`.

Cette configuration sert uniquement a valider le dialogue minimal Node -> Hub
sur la machine locale. Elle n'est pas une configuration reseau de production.

---

## Configuration actuelle

Sur l'hote `main`, l'edition reste :
- `server-headless`

Le Hub est active explicitement pour le test local :
- host : `127.0.0.1`
- port : `8787`

Le Node pointe vers ce Hub local :
- `http://127.0.0.1:8787`

Hub et Node utilisent un token local de developpement :
- fichier : `/etc/dimension/secrets/hub-dev-token`
- ce fichier est cree manuellement sur la machine (voir ci-dessous)
- ce fichier n'est jamais stocke dans Git

---

## Mise en place du token sur la machine

Le repertoire `/etc/dimension/secrets` est cree automatiquement par NixOS
via `systemd-tmpfiles` avec les permissions suivantes :
- mode : `0750`
- proprietaire : `root:dimension-secrets`
- groupe `dimension-secrets` : membres `dimension-hub` et `dimension-node`

Le fichier token doit etre cree manuellement apres le premier `nixos-rebuild` :

```sh
# creer le fichier vide avec les bonnes permissions
sudo install -m 640 -o root -g dimension-secrets \
  /dev/null /etc/dimension/secrets/hub-dev-token

# y ecrire un token aleatoire
openssl rand -hex 32 | sudo tee /etc/dimension/secrets/hub-dev-token > /dev/null
```

Ce fichier ne doit jamais etre versionne. Il n'apparait pas dans ce depot.

Apres creation du fichier, redemarrer les deux services :

```sh
sudo systemctl restart dimension-hub dimension-node
```

---

## Pourquoi un groupe partage

`dimension-hub` et `dimension-node` sont deux utilisateurs systeme distincts.
Pour qu'ils puissent tous les deux lire le meme fichier token sans duplication
et sans elargir les permissions :

- un groupe `dimension-secrets` est cree dans `hosts/main/configuration.nix`
- `dimension-hub` et `dimension-node` sont membres de ce groupe
- le repertoire est `0750 root:dimension-secrets`
- le fichier token est `0640 root:dimension-secrets`

Chaque service peut lire le fichier. Aucun ne peut l'ecrire. Root seul peut
modifier le secret.

---

## Commandes utiles

Tester directement le Hub (endpoint public, sans token) :

```sh
curl http://127.0.0.1:8787/ping
```

Tester avec le token (endpoints proteges) :

```sh
TOKEN="$(sudo cat /etc/dimension/secrets/hub-dev-token)"
curl --header "Authorization: Bearer $TOKEN" http://127.0.0.1:8787/nodes
```

Lister les nodes en attente d'approbation :

```sh
dimension-hub-admin list-pending
```

Approuver ou rejeter un node :

```sh
dimension-hub-admin approve <node_id>
dimension-hub-admin reject <node_id>
```

Verifier que le repertoire secrets existe :

```sh
ls -la /etc/dimension/secrets/
```

Lire les logs systemd du Hub :

```sh
journalctl -u dimension-hub
```

Lire les logs systemd du Node :

```sh
journalctl -u dimension-node
```

Suivre le log fichier du Hub :

```sh
tail -f /var/log/dimension-hub/hub.log
```

Suivre le log fichier du Node :

```sh
tail -f /var/log/dimension/node.log
```

---

## Limites importantes

Ce test n'est pas expose sur le LAN :
- le Hub ecoute sur `127.0.0.1`
- aucune ouverture firewall n'est ajoutee
- aucune interface reseau externe n'est visee

Ce test n'est pas securise pour un usage reseau :
- le token local est un secret partage simple, pas une authentification forte
- pairing manuel seulement
- pas de TLS
- pas de WireGuard
- pas de gestion de droits
- pas de protocole stable

Ce test est uniquement une etape de developpement locale.
Il valide que :
- le Hub peut repondre a `/ping`
- le Node peut poster son identite au Hub via `POST /nodes/ping`
- un nouveau Node apparait en `pending` jusqu'a approbation manuelle
- le Hub peut retourner la liste des nodes via `GET /nodes`
- le Hub peut approuver ou rejeter un node via `dimension-hub-admin`
- Hub et Node s'authentifient mutuellement par token local
- les deux services journalisent leur activite

Toute exposition reseau devra faire l'objet d'une phase explicite.
