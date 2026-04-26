# Dimension - Hub API locale

Ce document decrit l'API HTTP locale exposee par `dimension-hub`.

Cette API est une API de developpement minimal. Elle n'est pas destinee a etre
exposee sur le LAN ou sur Internet dans son etat actuel.

---

## Configuration par defaut

| Parametre | Valeur        |
|-----------|---------------|
| Host      | `127.0.0.1`   |
| Port      | `8787`        |
| Protocole | HTTP (pas TLS)|

Le hub ecoute uniquement sur `127.0.0.1` par defaut.
Aucun port n'est ouvert dans le firewall.
Aucune interface reseau externe n'est visee.

---

## Endpoints

### GET /ping

Verifie que le Hub est actif et repond.

**Requete :**

```sh
curl http://127.0.0.1:8787/ping
```

**Reponse succes :**

```
HTTP/1.1 200 OK
Content-Type: text/plain; charset=utf-8

ok
```

**Reponse erreur :** aucune (cet endpoint ne peut pas echouer si le Hub est actif).

---

### POST /nodes/ping

Enregistre ou met a jour un node dans le registre local du Hub.

Le node poste son identity.json. Le Hub extrait `node_id` et `hostname`,
puis stocke ou actualise l'entree dans `nodes.json`.

**Corps attendu (JSON) :**

```json
{
  "node_id": "550e8400-e29b-41d4-a716-446655440000",
  "hostname": "my-machine",
  "created_at": "2026-04-26T12:00:00+02:00",
  "version": 1
}
```

| Champ        | Type   | Obligatoire | Description                              |
|--------------|--------|-------------|------------------------------------------|
| `node_id`    | string | oui         | Identifiant unique du node (UUID)        |
| `hostname`   | string | non         | Nom d'hote de la machine                 |
| `created_at` | string | non         | Ignored par le Hub (conserve par le Node)|
| `version`    | int    | non         | Ignored par le Hub                       |

Seuls `node_id` et `hostname` sont lus et stockes par le Hub.
Les autres champs du payload sont ignores.

**Requete :**

```sh
curl --request POST \
     --header 'Content-Type: application/json' \
     --data '{"node_id":"550e8400-e29b-41d4-a716-446655440000","hostname":"my-machine"}' \
     http://127.0.0.1:8787/nodes/ping
```

Ou en postant directement l'identity.json du node :

```sh
curl --request POST \
     --header 'Content-Type: application/json' \
     --data-binary @/var/lib/dimension/node/identity.json \
     http://127.0.0.1:8787/nodes/ping
```

**Reponse succes :**

```
HTTP/1.1 200 OK
Content-Type: text/plain; charset=utf-8

ok
```

**Reponses erreur :**

| Code | Corps            | Cause                                 |
|------|------------------|---------------------------------------|
| 400  | `invalid json`   | Corps non parseable comme JSON        |
| 400  | `missing node_id`| Champ `node_id` absent ou vide        |

---

### GET /nodes

Retourne la liste de tous les nodes enregistres dans le registre local.

**Requete :**

```sh
curl http://127.0.0.1:8787/nodes
```

**Reponse succes :**

```
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8

[
  {
    "node_id": "550e8400-e29b-41d4-a716-446655440000",
    "hostname": "my-machine",
    "last_seen": "2026-04-26T12:00:00+02:00"
  }
]
```

Si aucun node n'est enregistre, la reponse est un tableau vide :

```json
[]
```

**Structure d'un node dans le registre :**

| Champ       | Type   | Description                                    |
|-------------|--------|------------------------------------------------|
| `node_id`   | string | Identifiant unique du node (UUID)              |
| `hostname`  | string | Nom d'hote (vide si non fourni par le node)    |
| `last_seen` | string | Horodatage ISO 8601 du dernier ping recu       |

**Reponse erreur :** aucune (retourne toujours un tableau JSON valide).

---

## Fichiers d'etat du Hub

| Fichier                                 | Contenu                              |
|-----------------------------------------|--------------------------------------|
| `/var/lib/dimension-hub/id`             | UUID du Hub (genere a la premiere activation) |
| `/var/lib/dimension-hub/identity.json`  | Identite du Hub (hub_id, hostname, created_at, version) |
| `/var/lib/dimension-hub/nodes.json`     | Registre local des nodes connus      |
| `/var/log/dimension-hub/hub.log`        | Log du Hub                           |

---

## Comportement du registre nodes.json

Lors d'un `POST /nodes/ping` :
- Si `node_id` est inconnu : un nouvel entree est ajoutee.
- Si `node_id` est deja connu : `hostname` et `last_seen` sont mis a jour.
- Les acces au registre sont proteges par un verrou thread-safe.

---

## Limites actuelles

Cette API est une API de developpement local minimal.

- API locale uniquement : le Hub ecoute sur `127.0.0.1` par defaut.
- Aucune authentification : toute requete est acceptee sans verification d'identite.
- Aucun pairing : n'importe quel client peut s'enregistrer comme node.
- Aucun TLS : les communications sont en clair.
- Aucun WireGuard : le Hub n'est pas integre au reseau VPN.
- Pas de suppression de node : aucun endpoint pour retirer un node du registre.
- Pas de validation avancee : seul `node_id` est verifie (presence et type).
- Pas de pagination : `GET /nodes` retourne tout le registre d'un coup.
- Pas pret pour exposition LAN : cette configuration ne doit pas etre exposee sur
  le reseau local tant que les points ci-dessus ne sont pas traites.

---

## Notes de securite

**Ne pas exposer cette API sur le reseau.**

Dans son etat actuel :
- Un attaquant ayant acces au port `8787` peut lire tous les nodes enregistres.
- Un attaquant peut injecter de faux nodes dans le registre.
- Aucune identite n'est verifiee.
- Aucun log d'audit lie a l'authentification n'est produit.

**Prochaine etape obligatoire avant toute exposition reseau :**

Avant de binder le Hub sur une interface LAN ou WireGuard, il faut au minimum :

1. Implementer un token de developpement local (header `Authorization`).
2. Valider le token sur chaque requete entrante.
3. Documenter et tester le mecanisme avant toute ouverture de port.

Se referer a [SECURITY.md](SECURITY.md) pour la checklist complete avant
exposition reseau.
