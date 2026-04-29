# Dimension - Hub API locale

Ce document decrit l'API HTTP locale exposee par `dimension-hub`.

Cette API est une API de developpement minimal. Elle n'est pas destinee a etre
exposee sur le LAN ou sur Internet dans son etat actuel.

---

## Configuration par defaut

| Parametre      | Valeur        |
|----------------|---------------|
| Host           | `127.0.0.1`   |
| Port           | `8787`        |
| Protocole      | HTTP (pas TLS)|
| Authentification | Bearer token (optionnel, voir ci-dessous) |

Le hub ecoute uniquement sur `127.0.0.1` par defaut.
Aucun port n'est ouvert dans le firewall.
Aucune interface reseau externe n'est visee.

---

## Authentification

L'authentification est controlee par l'option Nix `dimension.hub.devTokenFile`.

### Mode sans token (defaut)

Quand `devTokenFile` est vide (defaut), le Hub fonctionne en mode
developpement non authentifie. Il loggue un warning au demarrage :

```
WARNING: unauthenticated local dev mode (no devTokenFile configured)
```

Ce mode n'est acceptable que si le Hub reste bind sur `127.0.0.1`.

### Mode avec token

Quand `devTokenFile` pointe vers un fichier contenant un token :

```nix
dimension.hub.devTokenFile = "/run/credentials/dimension-hub.service/dev-token";
```

Le Hub lit le token au demarrage et exige pour les endpoints proteges :

```
Authorization: Bearer <token>
```

Le token n'est jamais loggue. Il n'est jamais stocke dans Git.

Les endpoints d'administration du pairing (`GET /nodes/pending`,
`POST /nodes/approve`, `POST /nodes/reject`) exigent qu'un token soit
configure. Sans token configure cote Hub, ils retournent `401`.

### Generer un token de developpement local

```sh
# generer et ecrire le token dans un fichier hors Git
openssl rand -hex 32 > /etc/dimension/hub/dev-token
chmod 600 /etc/dimension/hub/dev-token
chown dimension-hub:dimension-hub /etc/dimension/hub/dev-token
```

Ce chemin est deja inclus dans les `ReadWritePaths` autorises pour le service.

---

## Endpoints

### GET /ping

Verifie que le Hub est actif et repond.

Cet endpoint est **public** : aucun token requis.

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

Cet endpoint est **protege** : requiert `Authorization: Bearer <token>` si
`devTokenFile` est configure.

Le node poste son identity.json. Le Hub extrait `node_id`, `hostname` et
optionnellement `wg_pubkey`, puis stocke ou actualise l'entree dans
`nodes.json`.

Si le `node_id` est nouveau, le Hub cree une entree avec `status = "pending"`.
Si le `node_id` existe deja, le Hub met a jour `hostname`, `last_seen` et
`wg_pubkey`, mais conserve le `status` deja connu.

**Corps attendu (JSON) :**

```json
{
  "node_id": "550e8400-e29b-41d4-a716-446655440000",
  "hostname": "my-machine",
  "wg_pubkey": "base64-wireguard-public-key",
  "created_at": "2026-04-26T12:00:00+02:00",
  "version": 1
}
```

| Champ        | Type   | Obligatoire | Description                              |
|--------------|--------|-------------|------------------------------------------|
| `node_id`    | string | oui         | Identifiant unique du node (UUID)        |
| `hostname`   | string | non         | Nom d'hote de la machine                 |
| `wg_pubkey`  | string | non         | Cle publique WireGuard du node           |
| `created_at` | string | non         | Ignored par le Hub (conserve par le Node)|
| `version`    | int    | non         | Ignored par le Hub                       |

Seuls `node_id`, `hostname` et `wg_pubkey` sont lus et stockes par le Hub.
Les autres champs du payload sont ignores.

**Requete (mode non authentifie) :**

```sh
curl --request POST \
     --header 'Content-Type: application/json' \
     --data '{"node_id":"550e8400-e29b-41d4-a716-446655440000","hostname":"my-machine","wg_pubkey":"base64-wireguard-public-key"}' \
     http://127.0.0.1:8787/nodes/ping
```

**Requete (mode avec token) :**

```sh
curl --request POST \
     --header 'Content-Type: application/json' \
     --header 'Authorization: Bearer <token>' \
     --data '{"node_id":"550e8400-e29b-41d4-a716-446655440000","hostname":"my-machine","wg_pubkey":"base64-wireguard-public-key"}' \
     http://127.0.0.1:8787/nodes/ping
```

Ou en postant directement l'identity.json du node :

```sh
curl --request POST \
     --header 'Content-Type: application/json' \
     --header 'Authorization: Bearer <token>' \
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

| Code | Corps            | Cause                                        |
|------|------------------|----------------------------------------------|
| 401  | `unauthorized`   | Token absent ou incorrect (mode avec token)  |
| 400  | `invalid json`   | Corps non parseable comme JSON               |
| 400  | `missing node_id`| Champ `node_id` absent ou vide               |

---

### GET /nodes

Retourne la liste de tous les nodes enregistres dans le registre local.

Cet endpoint est **protege** : requiert `Authorization: Bearer <token>` si
`devTokenFile` est configure.

**Requete (mode non authentifie) :**

```sh
curl http://127.0.0.1:8787/nodes
```

**Requete (mode avec token) :**

```sh
curl --header 'Authorization: Bearer <token>' http://127.0.0.1:8787/nodes
```

**Reponse succes :**

```
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8

[
  {
    "node_id": "550e8400-e29b-41d4-a716-446655440000",
    "hostname": "my-machine",
    "last_seen": "2026-04-26T12:00:00+02:00",
    "wg_pubkey": "base64-wireguard-public-key",
    "status": "approved"
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
| `wg_pubkey` | string | Cle publique WireGuard connue du Hub           |
| `status`    | string | Etat de pairing : `pending`, `approved`, `rejected` |

**Reponses erreur :**

| Code | Corps          | Cause                                       |
|------|----------------|---------------------------------------------|
| 401  | `unauthorized` | Token absent ou incorrect (mode avec token) |

---

### GET /nodes/pending

Retourne la liste des nodes actuellement en attente d'approbation.

Cet endpoint est **protege** et **exige un token configure cote Hub**.

**Requete :**

```sh
curl --header 'Authorization: Bearer <token>' http://127.0.0.1:8787/nodes/pending
```

**Reponse succes :**

```json
[
  {
    "node_id": "550e8400-e29b-41d4-a716-446655440000",
    "hostname": "my-machine",
    "last_seen": "2026-04-26T12:00:00+02:00",
    "wg_pubkey": "base64-wireguard-public-key",
    "status": "pending"
  }
]
```

**Reponses erreur :**

| Code | Corps          | Cause                                               |
|------|----------------|-----------------------------------------------------|
| 401  | `unauthorized` | Token absent ou incorrect, ou aucun token configure |

---

### GET /wireguard/peers

Retourne la vue WireGuard minimale du registre local.

Cet endpoint est **protege** : requiert `Authorization: Bearer <token>` si
`devTokenFile` est configure.

Seuls les nodes **approuves** ayant un `wg_pubkey` non vide apparaissent dans
cette reponse.

**Requete (mode avec token) :**

```sh
curl --header 'Authorization: Bearer <token>' http://127.0.0.1:8787/wireguard/peers
```

**Reponse succes :**

```json
[
  {
    "node_id": "550e8400-e29b-41d4-a716-446655440000",
    "hostname": "my-machine",
    "wg_pubkey": "base64-wireguard-public-key",
    "last_seen": "2026-04-26T12:00:00+02:00"
  }
]
```

Cette vue ne configure encore aucun peer automatiquement.
Elle sert uniquement a exposer les cles publiques connues du Hub pour la suite
de l'integration VPN.

**Reponses erreur :**

| Code | Corps          | Cause                                       |
|------|----------------|---------------------------------------------|
| 401  | `unauthorized` | Token absent ou incorrect (mode avec token) |

---

### GET /wireguard/config?node_id=<id>

Retourne la configuration WireGuard minimale visible pour un node donne.

Cet endpoint est **protege** : requiert `Authorization: Bearer <token>` si
`devTokenFile` est configure.

Le `node_id` demandeur doit deja exister dans `nodes.json`, sinon le Hub
retourne `404`.

Seuls les **autres** nodes **approuves** ayant un `wg_pubkey` non vide
apparaissent dans la reponse. Le node demandeur n'est jamais inclus dans sa
propre liste.

**Requete (mode avec token) :**

```sh
curl --header 'Authorization: Bearer <token>' \
     'http://127.0.0.1:8787/wireguard/config?node_id=550e8400-e29b-41d4-a716-446655440000'
```

**Reponse succes :**

```json
[
  {
    "node_id": "11111111-1111-1111-1111-111111111111",
    "hostname": "peer-a",
    "wg_pubkey": "base64-wireguard-public-key-a"
  },
  {
    "node_id": "22222222-2222-2222-2222-222222222222",
    "hostname": "peer-b",
    "wg_pubkey": "base64-wireguard-public-key-b"
  }
]
```

Cette vue est destinee au `dimension-node`, qui la persiste localement pour une
future etape d'application sur l'interface WireGuard.

**Reponses erreur :**

| Code | Corps             | Cause                                       |
|------|-------------------|---------------------------------------------|
| 401  | `unauthorized`    | Token absent ou incorrect (mode avec token) |
| 400  | `missing node_id` | Parametre `node_id` absent ou vide          |
| 404  | `node not found`  | `node_id` inconnu dans `nodes.json`         |

---

### POST /nodes/approve

Approuve manuellement un node en attente ou deja connu.

Cet endpoint est **protege** et **exige un token configure cote Hub**.

**Corps attendu (JSON) :**

```json
{
  "node_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Requete :**

```sh
curl --request POST \
     --header 'Content-Type: application/json' \
     --header 'Authorization: Bearer <token>' \
     --data '{"node_id":"550e8400-e29b-41d4-a716-446655440000"}' \
     http://127.0.0.1:8787/nodes/approve
```

**Reponse succes :**

```
HTTP/1.1 200 OK
Content-Type: text/plain; charset=utf-8

ok
```

**Reponses erreur :**

| Code | Corps            | Cause                                               |
|------|------------------|-----------------------------------------------------|
| 401  | `unauthorized`   | Token absent ou incorrect, ou aucun token configure |
| 400  | `invalid json`   | Corps non parseable comme JSON                      |
| 400  | `missing node_id`| Champ `node_id` absent ou vide                      |
| 404  | `node not found` | `node_id` inconnu dans `nodes.json`                 |

---

### POST /nodes/reject

Rejette manuellement un node en attente ou deja connu.

Cet endpoint est **protege** et **exige un token configure cote Hub**.

**Corps attendu (JSON) :**

```json
{
  "node_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Requete :**

```sh
curl --request POST \
     --header 'Content-Type: application/json' \
     --header 'Authorization: Bearer <token>' \
     --data '{"node_id":"550e8400-e29b-41d4-a716-446655440000"}' \
     http://127.0.0.1:8787/nodes/reject
```

**Reponse succes :**

```
HTTP/1.1 200 OK
Content-Type: text/plain; charset=utf-8

ok
```

**Reponses erreur :**

| Code | Corps            | Cause                                               |
|------|------------------|-----------------------------------------------------|
| 401  | `unauthorized`   | Token absent ou incorrect, ou aucun token configure |
| 400  | `invalid json`   | Corps non parseable comme JSON                      |
| 400  | `missing node_id`| Champ `node_id` absent ou vide                      |
| 404  | `node not found` | `node_id` inconnu dans `nodes.json`                 |

---

## Fichiers d'etat du Hub

| Fichier                                 | Contenu                              |
|-----------------------------------------|--------------------------------------|
| `/var/lib/dimension-hub/id`             | UUID du Hub (genere a la premiere activation) |
| `/var/lib/dimension-hub/identity.json`  | Identite du Hub (hub_id, hostname, created_at, version) |
| `/var/lib/dimension-hub/nodes.json`     | Registre local des nodes connus et de leur statut |
| `/var/log/dimension-hub/hub.log`        | Log du Hub                           |

---

## Comportement du registre nodes.json

Lors d'un `POST /nodes/ping` :
- Si `node_id` est inconnu : un nouvel entree est ajoutee avec `status = "pending"`.
- Si `node_id` est deja connu : `hostname`, `last_seen` et `wg_pubkey` sont mis a jour, mais `status` est conserve.
- Si une ancienne entree ne contient pas `status`, le Hub la traite comme `approved` pour compatibilite.
- Les acces au registre sont proteges par un verrou thread-safe.

---

## Limites actuelles

Cette API est une API de developpement local minimal.

- API locale uniquement : le Hub ecoute sur `127.0.0.1` par defaut.
- Authentification optionnelle par token local : sans `devTokenFile`, toute
  requete est acceptee sans verification d'identite.
- Le token est un secret partage simple, pas une authentification forte.
- Pairing manuel uniquement : les nouveaux nodes restent `pending` jusqu'a une approbation explicite.
- Aucun TLS : les communications sont en clair (acceptable sur loopback uniquement).
- Le Hub distribue maintenant une liste JSON de peers, mais ne configure encore aucun VPN.
- `GET /wireguard/peers` et `GET /wireguard/config` exposent seulement des vues lecture des cles publiques des nodes approuves.
- Pas de suppression de node : aucun endpoint pour retirer un node du registre.
- Pas de validation avancee : seul `node_id` est verifie (presence et type).
- Pas de pagination : `GET /nodes` retourne tout le registre d'un coup.
- Pas pret pour exposition LAN : cette configuration ne doit pas etre exposee sur
  le reseau local dans son etat actuel.

---

## Notes de securite

**Ne pas exposer cette API sur le reseau.**

Sans `devTokenFile` configure :
- Toute requete locale est acceptee sans verification d'identite.
- Ce mode ne doit etre utilise que sur `127.0.0.1` en environnement de
  developpement local isole.
- Les endpoints d'administration du pairing ne sont pas utilisables et
  retournent `401`.

Avec `devTokenFile` configure :
- Les endpoints proteges (`POST /nodes/ping`, `GET /nodes`, `GET /wireguard/peers`, `GET /wireguard/config`) exigent un token.
- Les endpoints d'administration du pairing (`GET /nodes/pending`, `POST /nodes/approve`, `POST /nodes/reject`) exigent un token valide et un token configure cote Hub.
- Le token n'est jamais loggue.
- Le token ne doit jamais etre stocke dans Git.
- Ce mode reste insuffisant pour une exposition LAN.

**Avant toute exposition reseau (LAN ou WireGuard) :**

Le token de developpement local est une protection minimale de loopback.
Elle ne suffit pas pour exposer le Hub sur le reseau. Il faudra au minimum :

1. Authentification forte (pas un simple secret partage en clair sur HTTP).
2. TLS ou tunnel chiffre (WireGuard).
3. Pairing explicite et valide.
4. Protocole documente et teste.
5. Checklist [SECURITY.md](SECURITY.md) completement validee.

Se referer a [SECURITY.md](SECURITY.md) pour la checklist complete avant
exposition reseau.
