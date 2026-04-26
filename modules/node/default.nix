{ config, lib, pkgs, ... }:

let
  cfg = config.dimension.node;
  agentScript = pkgs.writeShellScript "dimension-node-agent" ''
    set -eu

    state_dir="''${DIMENSION_NODE_STATE_DIR:-/var/lib/dimension/node}"
    log_dir="''${DIMENSION_NODE_LOG_DIR:-/var/log/dimension}"
    id_file="$state_dir/id"
    log_file="$log_dir/node.log"

    mkdir -p "$state_dir" "$log_dir"

    log() {
      timestamp="$(${pkgs.coreutils}/bin/date -Is)"
      ${pkgs.coreutils}/bin/printf '%s dimension-node: %s\n' "$timestamp" "$*" | ${pkgs.coreutils}/bin/tee -a "$log_file"
    }

    log "starting"

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
      ${pkgs.coreutils}/bin/sleep 60
    done
  '';
in
{
  options.dimension.node.enable = lib.mkEnableOption "Dimension local node agent";

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
      };
    };
  };
}
