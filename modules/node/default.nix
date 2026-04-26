{ config, lib, pkgs, ... }:

let
  cfg = config.dimension.node;
  agentScript = pkgs.writeShellScript "dimension-node-agent" ''
    set -eu

    state_dir="''${DIMENSION_NODE_STATE_DIR:-/var/lib/dimension/node}"
    log_dir="''${DIMENSION_NODE_LOG_DIR:-/var/log/dimension}"
    hub_url=${lib.escapeShellArg cfg.hubUrl}
    id_file="$state_dir/id"
    log_file="$log_dir/node.log"

    mkdir -p "$state_dir" "$log_dir"

    log() {
      timestamp="$(${pkgs.coreutils}/bin/date -Is)"
      ${pkgs.coreutils}/bin/printf '%s dimension-node: %s\n' "$timestamp" "$*" | ${pkgs.coreutils}/bin/tee -a "$log_file"
    }

    log "starting"

    if [ -n "$hub_url" ]; then
      log "hub url configured: $hub_url"
    else
      log "local mode: no hub url configured"
    fi

    if [ ! -s "$id_file" ]; then
      if [ -r /proc/sys/kernel/random/uuid ]; then
        read -r node_id < /proc/sys/kernel/random/uuid
      else
        node_id="dimension-$(${pkgs.coreutils}/bin/date +%s)"
      fi

      ${pkgs.coreutils}/bin/printf '%s\n' "$node_id" > "$id_file"
      ${pkgs.coreutils}/bin/chmod 0644 "$id_file"
      log "created node id"
    else
      log "node id exists"
    fi

    while true; do
      log "timestamp"

      if [ -n "$hub_url" ]; then
        if curl_error="$(${pkgs.curl}/bin/curl --fail --silent --show-error --max-time 5 "$hub_url/ping" 2>&1 >/dev/null)"; then
          log "hub ping succeeded"
        else
          log "hub ping failed: $curl_error"
        fi
      fi

      ${pkgs.coreutils}/bin/sleep 60
    done
  '';
in
{
  options.dimension.node = {
    enable = lib.mkEnableOption "Dimension local node agent";

    hubUrl = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Optional Dimension Hub base URL used by the local node agent.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d /var/lib/dimension/node 0755 root root -"
      "d /var/log/dimension 0755 root root -"
      "L+ /var/lib/dimension/node/agent.sh - - - - ${agentScript}"
    ];

    systemd.services.dimension-node = {
      description = "Dimension node agent";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-tmpfiles-setup.service" ];

      serviceConfig = {
        Type = "simple";
        User = "root";
        ExecStart = "/var/lib/dimension/node/agent.sh";
        Restart = "always";
        RestartSec = "5s";
        StandardOutput = "journal";
        StandardError = "journal";
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [
          "/var/lib/dimension/node"
          "/var/log/dimension"
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
