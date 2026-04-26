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

## Commandes utiles

Tester directement le Hub :

```sh
curl http://127.0.0.1:8787/ping
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
- pas d'authentification
- pas de pairing
- pas de TLS
- pas de WireGuard
- pas de gestion de droits
- pas de protocole stable

Ce test est uniquement une etape de developpement locale.
Il valide que :
- le Hub peut repondre a `/ping`
- le Node peut appeler `/ping`
- les deux services journalisent leur activite

Toute exposition reseau devra faire l'objet d'une phase explicite.
