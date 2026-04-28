{ config, lib, pkgs, ... }:

let
  cfg = config.dimension.hub;
  hubServer = pkgs.writeText "dimension-hub-server.py" ''
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from datetime import datetime, timezone
from urllib.parse import unquote_plus
import json
import os
import socket
import sys
import threading
import uuid

VALID_NODE_STATUSES = {"pending", "approved", "rejected"}

state_dir = Path(os.environ.get("DIMENSION_HUB_STATE_DIR", "/var/lib/dimension-hub"))
log_dir = Path(os.environ.get("DIMENSION_HUB_LOG_DIR", "/var/log/dimension-hub"))
config_dir = Path(os.environ.get("DIMENSION_HUB_CONFIG_DIR", "/etc/dimension/hub"))
host = os.environ.get("DIMENSION_HUB_HOST", ${builtins.toJSON cfg.host})
port = int(os.environ.get("DIMENSION_HUB_PORT", ${toString cfg.port}))
dev_token_file = os.environ.get("DIMENSION_HUB_DEV_TOKEN_FILE", "")
id_file = state_dir / "id"
identity_file = state_dir / "identity.json"
nodes_file = state_dir / "nodes.json"
log_file = log_dir / "hub.log"
nodes_lock = threading.Lock()

state_dir.mkdir(parents=True, exist_ok=True)
log_dir.mkdir(parents=True, exist_ok=True)
config_dir.mkdir(parents=True, exist_ok=True)

def log(message):
    timestamp = datetime.now(timezone.utc).astimezone().isoformat(timespec="seconds")
    line = f"{timestamp} dimension-hub: {message}"
    with log_file.open("a", encoding="utf-8") as handle:
        handle.write(line + "\n")
    print(line, flush=True)

log("starting")

dev_token = None
if dev_token_file:
    token_path = Path(dev_token_file)
    if token_path.exists():
        raw = token_path.read_text(encoding="utf-8").strip()
        if raw:
            dev_token = raw
            log("dev token loaded")
        else:
            log("WARNING: dev token file is empty, falling back to unauthenticated local dev mode")
    else:
        log("WARNING: dev token file not found, falling back to unauthenticated local dev mode")
else:
    log("WARNING: unauthenticated local dev mode (no devTokenFile configured)")

if not id_file.exists() or not id_file.read_text(encoding="utf-8").strip():
    id_file.write_text(str(uuid.uuid4()) + "\n", encoding="utf-8")
    id_file.chmod(0o644)
    log("created hub id")
else:
    log("hub id exists")

hub_id = id_file.read_text(encoding="utf-8").strip()

if not identity_file.exists() or not identity_file.read_text(encoding="utf-8").strip():
    identity = {
        "hub_id": hub_id,
        "hostname": socket.gethostname(),
        "created_at": datetime.now(timezone.utc).astimezone().isoformat(timespec="seconds"),
        "version": 1,
    }
    identity_file.write_text(json.dumps(identity, indent=2) + "\n", encoding="utf-8")
    identity_file.chmod(0o644)
    log("created hub identity")
else:
    log("hub identity exists")

if not nodes_file.exists() or not nodes_file.read_text(encoding="utf-8").strip():
    nodes_file.write_text("[]\n", encoding="utf-8")
    nodes_file.chmod(0o644)
    log("created nodes registry")
else:
    log("nodes registry exists")

def current_timestamp():
    return datetime.now(timezone.utc).astimezone().isoformat(timespec="seconds")

def log_value(value):
    return str(value).replace("\n", " ").replace("\r", " ")[:128]

def check_auth(handler, require_token=False):
    if dev_token is None:
        return not require_token
    auth = handler.headers.get("Authorization", "")
    if not auth.startswith("Bearer "):
        return False
    return auth[len("Bearer "):] == dev_token

def normalize_node_status(node):
    raw_status = node.get("status")
    if raw_status is None:
        return "approved"

    if isinstance(raw_status, str):
        status = raw_status.strip()
    else:
        status = ""

    if status in VALID_NODE_STATUSES:
        return status

    return "rejected"

def read_nodes():
    data = json.loads(nodes_file.read_text(encoding="utf-8"))
    if not isinstance(data, list):
        return []
    nodes = []
    for node in data:
        if not isinstance(node, dict):
            continue
        nodes.append({
            "node_id": str(node.get("node_id", "")).strip(),
            "hostname": str(node.get("hostname", "")).strip(),
            "last_seen": str(node.get("last_seen", "")).strip(),
            "wg_pubkey": str(node.get("wg_pubkey", "")).strip(),
            "status": normalize_node_status(node),
        })
    return [node for node in nodes if node["node_id"]]

def write_nodes(nodes):
    nodes_file.write_text(json.dumps(nodes, indent=2) + "\n", encoding="utf-8")
    nodes_file.chmod(0o644)

def parse_query_string(path):
    _, _, query = path.partition("?")
    params = {}
    if not query:
        return params

    for pair in query.split("&"):
        if not pair:
            continue

        key, sep, value = pair.partition("=")
        key = unquote_plus(key)
        value = unquote_plus(value) if sep else ""

        if key not in params:
            params[key] = []
        params[key].append(value)

    return params

def list_wireguard_peers():
    peers = []
    for node in read_nodes():
        if node.get("status") != "approved":
            continue
        if not node.get("wg_pubkey"):
            continue
        peers.append({
            "node_id": node["node_id"],
            "hostname": node["hostname"],
            "wg_pubkey": node["wg_pubkey"],
            "last_seen": node["last_seen"],
        })
    return peers

def list_wireguard_config(node_id):
    nodes = read_nodes()
    node_exists = False
    peers = []

    for node in nodes:
        if node["node_id"] == node_id:
            node_exists = True
            continue

        if node.get("status") != "approved":
            continue

        if not node.get("wg_pubkey"):
            continue

        peers.append({
            "node_id": node["node_id"],
            "hostname": node["hostname"],
            "wg_pubkey": node["wg_pubkey"],
        })

    return node_exists, peers

def list_pending_nodes():
    return [node for node in read_nodes() if node.get("status") == "pending"]

def update_node_status(nodes, node_id, status):
    for node in nodes:
        if node.get("node_id") != node_id:
            continue

        previous_status = node.get("status", "approved")
        node["status"] = status
        return previous_status

    return None

class Handler(BaseHTTPRequestHandler):
    def send_text(self, status, body):
        data = body.encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def send_json(self, status, body):
        data = (json.dumps(body, indent=2) + "\n").encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def read_json_payload(self, endpoint):
        length = int(self.headers.get("Content-Length", "0"))
        try:
            payload = json.loads(self.rfile.read(length).decode("utf-8"))
        except json.JSONDecodeError:
            self.send_text(400, "invalid json\n")
            log(f"POST {endpoint} 400 invalid json")
            return None

        if not isinstance(payload, dict):
            self.send_text(400, "invalid json\n")
            log(f"POST {endpoint} 400 invalid payload")
            return None

        return payload

    def read_required_node_id(self, payload, endpoint):
        node_id = payload.get("node_id")
        if not isinstance(node_id, str) or not node_id.strip():
            self.send_text(400, "missing node_id\n")
            log(f"POST {endpoint} 400 missing node_id")
            return None

        return node_id.strip()

    def handle_node_status_update(self, endpoint, target_status):
        if not check_auth(self, require_token=True):
            self.send_text(401, "unauthorized\n")
            log(f"POST {endpoint} 401 from {self.client_address[0]}")
            return

        payload = self.read_json_payload(endpoint)
        if payload is None:
            return

        node_id = self.read_required_node_id(payload, endpoint)
        if node_id is None:
            return

        with nodes_lock:
            nodes = read_nodes()
            previous_status = update_node_status(nodes, node_id, target_status)
            if previous_status is None:
                self.send_text(404, "node not found\n")
                log(f"POST {endpoint} 404 node_id={log_value(node_id)}")
                return
            write_nodes(nodes)

        self.send_text(200, "ok\n")
        log(
            f"node status updated: node_id={log_value(node_id)} "
            f"from={previous_status} to={target_status}"
        )

    def do_GET(self):
        request_path, _, _ = self.path.partition("?")

        if request_path == "/ping":
            self.send_text(200, "ok\n")
            log(f"GET /ping 200 from {self.client_address[0]}")
            return

        if request_path == "/nodes":
            if not check_auth(self):
                self.send_text(401, "unauthorized\n")
                log(f"GET /nodes 401 from {self.client_address[0]}")
                return
            with nodes_lock:
                nodes = read_nodes()
            self.send_json(200, nodes)
            log("GET /nodes 200")
            return

        if request_path == "/nodes/pending":
            if not check_auth(self, require_token=True):
                self.send_text(401, "unauthorized\n")
                log(f"GET /nodes/pending 401 from {self.client_address[0]}")
                return
            with nodes_lock:
                nodes = list_pending_nodes()
            self.send_json(200, nodes)
            log(f"GET /nodes/pending 200 count={len(nodes)}")
            return

        if request_path == "/wireguard/peers":
            if not check_auth(self):
                self.send_text(401, "unauthorized\n")
                log(f"GET /wireguard/peers 401 from {self.client_address[0]}")
                return
            with nodes_lock:
                peers = list_wireguard_peers()
            self.send_json(200, peers)
            log("GET /wireguard/peers 200")
            return

        if request_path == "/wireguard/config":
            if not check_auth(self):
                self.send_text(401, "unauthorized\n")
                log(f"GET /wireguard/config 401 from {self.client_address[0]}")
                return

            params = parse_query_string(self.path)
            node_values = params.get("node_id", [])
            node_id = node_values[0].strip() if node_values else ""
            if not node_id:
                self.send_text(400, "missing node_id\n")
                log("GET /wireguard/config 400 missing node_id")
                return

            with nodes_lock:
                node_exists, peers = list_wireguard_config(node_id)

            if not node_exists:
                self.send_text(404, "node not found\n")
                log(f"GET /wireguard/config 404 node_id={log_value(node_id)}")
                return

            self.send_json(200, peers)
            log(
                f"GET /wireguard/config 200 node_id={log_value(node_id)} "
                f"peers={len(peers)}"
            )
            return

        self.send_response(404)
        self.send_header("Content-Length", "0")
        self.end_headers()
        log(f"GET {self.path} 404 from {self.client_address[0]}")

    def do_POST(self):
        if self.path == "/nodes/approve":
            self.handle_node_status_update("/nodes/approve", "approved")
            return

        if self.path == "/nodes/reject":
            self.handle_node_status_update("/nodes/reject", "rejected")
            return

        if self.path != "/nodes/ping":
            self.send_response(404)
            self.send_header("Content-Length", "0")
            self.end_headers()
            log(f"POST {self.path} 404 from {self.client_address[0]}")
            return

        if not check_auth(self):
            self.send_text(401, "unauthorized\n")
            log(f"POST /nodes/ping 401 from {self.client_address[0]}")
            return

        payload = self.read_json_payload("/nodes/ping")
        if payload is None:
            return

        node_id = self.read_required_node_id(payload, "/nodes/ping")
        if node_id is None:
            return

        hostname = payload.get("hostname", "")
        if not isinstance(hostname, str):
            hostname = ""
        hostname = hostname.strip()
        wg_pubkey = payload.get("wg_pubkey", "")
        if not isinstance(wg_pubkey, str):
            wg_pubkey = ""
        wg_pubkey = wg_pubkey.strip()
        last_seen = current_timestamp()

        with nodes_lock:
            nodes = read_nodes()
            updated = False
            node_status = "pending"

            for node in nodes:
                if node.get("node_id") == node_id:
                    node["hostname"] = hostname
                    node["last_seen"] = last_seen
                    node["wg_pubkey"] = wg_pubkey
                    node_status = node.get("status", "approved")
                    updated = True
                    break

            if not updated:
                nodes.append({
                    "node_id": node_id,
                    "hostname": hostname,
                    "last_seen": last_seen,
                    "wg_pubkey": wg_pubkey,
                    "status": "pending",
                })

            write_nodes(nodes)

        log(
            f"node ping stored: node_id={log_value(node_id)} "
            f"hostname={log_value(hostname)} wg_pubkey={'yes' if wg_pubkey else 'no'} "
            f"status={node_status}"
        )
        self.send_text(200, "ok\n")

    def log_message(self, format, *args):
        return

server = ThreadingHTTPServer((host, port), Handler)
log(f"listening on {host}:{port}")

try:
    server.serve_forever()
except KeyboardInterrupt:
    log("stopping")
    server.server_close()
    sys.exit(0)
  '';
  hubScript = pkgs.writeShellScript "dimension-hub-agent" ''
    exec ${pkgs.python3}/bin/python3 ${hubServer}
  '';
  hubAvahiServiceFile = pkgs.writeText "dimension-hub.service" ''
    <?xml version="1.0" standalone="no"?>
    <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
    <service-group>
      <name replace-wildcards="yes">Dimension Hub on %h</name>
      <service>
        <type>_dimension-hub._tcp</type>
        <port>${toString cfg.port}</port>
      </service>
    </service-group>
  '';
  hubAdminScript = pkgs.writeShellScript "dimension-hub-admin" ''
    set -eu

    hub_url="''${DIMENSION_HUB_URL:-http://127.0.0.1:8787}"
    token_file="''${DIMENSION_HUB_DEV_TOKEN_FILE:-/etc/dimension/secrets/hub-dev-token}"

    if [ ! -s "$token_file" ]; then
      ${pkgs.coreutils}/bin/printf 'dimension-hub-admin: token file not found or empty: %s\n' "$token_file" >&2
      exit 1
    fi

    token="$(${pkgs.coreutils}/bin/cat "$token_file")"
    auth_args=(--header "Authorization: Bearer $token")

    usage() {
      ${pkgs.coreutils}/bin/cat <<'EOF'
Usage:
  dimension-hub-admin list-pending
  dimension-hub-admin approve <node_id>
  dimension-hub-admin reject <node_id>
EOF
    }

    encode_payload() {
      ${pkgs.python3}/bin/python3 -c "
import json
import sys

print(json.dumps({'node_id': sys.argv[1]}))
" "$1"
    }

    if [ "$#" -lt 1 ]; then
      usage >&2
      exit 1
    fi

    command="$1"

    case "$command" in
      list-pending)
        if [ "$#" -ne 1 ]; then
          usage >&2
          exit 1
        fi

        exec ${pkgs.curl}/bin/curl --fail --silent --show-error "''${auth_args[@]}" "$hub_url/nodes/pending"
        ;;
      approve|reject)
        if [ "$#" -ne 2 ] || [ -z "$2" ]; then
          usage >&2
          exit 1
        fi

        payload="$(encode_payload "$2")"
        endpoint="/nodes/$command"
        exec ${pkgs.curl}/bin/curl --fail --silent --show-error \
          --request POST \
          --header 'Content-Type: application/json' \
          "''${auth_args[@]}" \
          --data-binary "$payload" \
          "$hub_url$endpoint"
        ;;
      *)
        usage >&2
        exit 1
        ;;
    esac
  '';
in
{
  options.dimension.hub = {
    enable = lib.mkEnableOption "Dimension central hub foundation";

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Host address used by the minimal Dimension Hub HTTP server.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8787;
      description = "Port used by the minimal Dimension Hub HTTP server.";
    };

    advertise = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to advertise the Hub over Avahi/mDNS as `_dimension-hub._tcp`
        on the configured port.
      '';
    };

    devTokenFile = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        Path to a file containing a bearer token used to authenticate requests
        to protected Hub API endpoints (POST /nodes/ping, GET /nodes).
        This also protects GET /wireguard/peers, GET /wireguard/config,
        GET /nodes/pending, POST /nodes/approve, and POST /nodes/reject.
        When empty, the Hub runs in unauthenticated local dev mode and logs a
        warning. The token must never be stored in Git.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ hubAdminScript ];
    environment.etc = lib.mkIf cfg.advertise {
      "avahi/services/dimension-hub.service".source = hubAvahiServiceFile;
    };

    users.groups.dimension-hub = {};

    users.users.dimension-hub = {
      isSystemUser = true;
      group = "dimension-hub";
      description = "Dimension Hub service user";
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/dimension-hub 0750 dimension-hub dimension-hub -"
      "d /var/log/dimension-hub 0750 dimension-hub dimension-hub -"
      "d /etc/dimension/hub 0750 dimension-hub dimension-hub -"
      "L+ /var/lib/dimension-hub/hub.sh - dimension-hub dimension-hub - ${hubScript}"
    ];

    systemd.services.dimension-hub = {
      description = "Dimension hub agent";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-tmpfiles-setup.service" ];

      serviceConfig = {
        Type = "simple";
        User = "dimension-hub";
        Group = "dimension-hub";
        ExecStart = "/var/lib/dimension-hub/hub.sh";
        Restart = "always";
        RestartSec = "5s";
        StandardOutput = "journal";
        StandardError = "journal";
        Environment = lib.optional (cfg.devTokenFile != "") "DIMENSION_HUB_DEV_TOKEN_FILE=${cfg.devTokenFile}";
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [
          "/var/lib/dimension-hub"
          "/var/log/dimension-hub"
          "/etc/dimension/hub"
        ];
        RestrictAddressFamilies = [
          "AF_UNIX"
          "AF_INET"
          "AF_INET6"
        ];
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        SystemCallArchitectures = "native";
      };
    };

    systemd.services.dimension-hub-avahi = lib.mkIf cfg.advertise {
      description = "Dimension hub Avahi advertisement";
      wantedBy = [ "multi-user.target" ];
      after = [ "local-fs.target" ];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.coreutils}/bin/test -f /etc/avahi/services/dimension-hub.service";
        RemainAfterExit = true;
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        RestrictAddressFamilies = [ "AF_UNIX" ];
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        SystemCallArchitectures = "native";
      };
    };
  };
}
