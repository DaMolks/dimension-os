{ config, lib, pkgs, ... }:

let
  cfg = config.dimension.hub;
  hubServer = pkgs.writeText "dimension-hub-server.py" ''
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from datetime import datetime, timezone
import json
import os
import socket
import sys
import threading
import uuid

state_dir = Path(os.environ.get("DIMENSION_HUB_STATE_DIR", "/var/lib/dimension-hub"))
log_dir = Path(os.environ.get("DIMENSION_HUB_LOG_DIR", "/var/log/dimension-hub"))
config_dir = Path(os.environ.get("DIMENSION_HUB_CONFIG_DIR", "/etc/dimension/hub"))
host = os.environ.get("DIMENSION_HUB_HOST", ${builtins.toJSON cfg.host})
port = int(os.environ.get("DIMENSION_HUB_PORT", ${toString cfg.port}))
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

def read_nodes():
    data = json.loads(nodes_file.read_text(encoding="utf-8"))
    if not isinstance(data, list):
        return []
    return [node for node in data if isinstance(node, dict)]

def write_nodes(nodes):
    nodes_file.write_text(json.dumps(nodes, indent=2) + "\n", encoding="utf-8")
    nodes_file.chmod(0o644)

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

    def do_GET(self):
        if self.path == "/ping":
            self.send_text(200, "ok\n")
            log(f"GET /ping 200 from {self.client_address[0]}")
            return

        if self.path == "/nodes":
            with nodes_lock:
                nodes = read_nodes()
            self.send_json(200, nodes)
            log("GET /nodes 200")
            return

        self.send_response(404)
        self.send_header("Content-Length", "0")
        self.end_headers()
        log(f"GET {self.path} 404 from {self.client_address[0]}")

    def do_POST(self):
        if self.path != "/nodes/ping":
            self.send_response(404)
            self.send_header("Content-Length", "0")
            self.end_headers()
            log(f"POST {self.path} 404 from {self.client_address[0]}")
            return

        length = int(self.headers.get("Content-Length", "0"))
        try:
            payload = json.loads(self.rfile.read(length).decode("utf-8"))
        except json.JSONDecodeError:
            self.send_text(400, "invalid json\n")
            log("POST /nodes/ping 400 invalid json")
            return

        if not isinstance(payload, dict):
            self.send_text(400, "invalid json\n")
            log("POST /nodes/ping 400 invalid payload")
            return

        node_id = payload.get("node_id")
        if not isinstance(node_id, str) or not node_id.strip():
            self.send_text(400, "missing node_id\n")
            log("POST /nodes/ping 400 missing node_id")
            return

        node_id = node_id.strip()
        hostname = payload.get("hostname", "")
        if not isinstance(hostname, str):
            hostname = ""
        hostname = hostname.strip()
        last_seen = current_timestamp()

        with nodes_lock:
            nodes = read_nodes()
            updated = False

            for node in nodes:
                if node.get("node_id") == node_id:
                    node["hostname"] = hostname
                    node["last_seen"] = last_seen
                    updated = True
                    break

            if not updated:
                nodes.append({
                    "node_id": node_id,
                    "hostname": hostname,
                    "last_seen": last_seen,
                })

            write_nodes(nodes)

        log(f"node ping stored: node_id={log_value(node_id)} hostname={log_value(hostname)}")
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
  };

  config = lib.mkIf cfg.enable {
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
  };
}
