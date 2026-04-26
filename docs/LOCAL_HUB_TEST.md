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

Le ping effectue par le Node cible donc :
- `http://127.0.0.1:8787/ping`

Le Hub repond actuellement :
- statut HTTP : `200`
- body : `ok`

---

## Authentification locale par token (optionnel)

Hub et Node supportent un token local de developpement.
Ce token protege les endpoints `POST /nodes/ping` et `GET /nodes` sans exposer
de secret dans Git.

### Configurer le token cote Hub

```nix
dimension.hub.devTokenFile = "/etc/dimension/hub/dev-token";
```

Generer le token (hors Git, une seule fois) :

```sh
openssl rand -hex 32 > /etc/dimension/hub/dev-token
chmod 640 /etc/dimension/hub/dev-token
chown dimension-hub:dimension-hub /etc/dimension/hub/dev-token
```

### Configurer le token cote Node

```nix
dimension.node.hubTokenFile = "/etc/dimension/hub/dev-token";
```

Le meme fichier peut etre partage entre Hub et Node sur la meme machine.
Le Node lit le fichier au demarrage et envoie le token dans le header
`Authorization: Bearer <token>` a chaque `POST /nodes/ping`.

La permission minimale pour que le Node puisse lire le fichier :

```sh
chmod 640 /etc/dimension/hub/dev-token
chown dimension-hub:dimension-hub /etc/dimension/hub/dev-token
# ajouter dimension-node au groupe dimension-hub si necessaire
usermod -aG dimension-hub dimension-node
```

Ou creer un fichier dedie lisible par dimension-node :

```sh
install -m 640 -o dimension-node -g dimension-node \
  /etc/dimension/hub/dev-token \
  /etc/dimension/node/hub-token
```

```nix
dimension.node.hubTokenFile = "/etc/dimension/node/hub-token";
```

### Sans token (mode developpement local non authentifie)

Laisser `devTokenFile` et `hubTokenFile` vides.
Le Hub loggue un warning au demarrage et accepte toutes les requetes.
Ce mode ne doit etre utilise que si le Hub reste bind sur `127.0.0.1`.

---

## Commandes utiles

Tester directement le Hub (endpoint public) :

```sh
curl http://127.0.0.1:8787/ping
```

Tester avec token :

```sh
TOKEN="$(cat /etc/dimension/hub/dev-token)"
curl --header "Authorization: Bearer $TOKEN" http://127.0.0.1:8787/nodes
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
- pas de pairing
- pas de TLS
- pas de WireGuard
- pas de gestion de droits
- pas de protocole stable

Ce test est uniquement une etape de developpement locale.
Il valide que :
- le Hub peut repondre a `/ping`
- le Node peut poster son identite au Hub via `POST /nodes/ping`
- le Hub peut retourner la liste des nodes via `GET /nodes`
- Hub et Node peuvent s'authentifier mutuellement par token local si configure
- les deux services journalisent leur activite

Toute exposition reseau devra faire l'objet d'une phase explicite.
