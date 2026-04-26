{ config, lib, pkgs, ... }:

let
  cfg = config.dimension.hub;
  hubScript = pkgs.writeShellScript "dimension-hub-agent" ''
    set -eu

    state_dir="''${DIMENSION_HUB_STATE_DIR:-/var/lib/dimension-hub}"
    log_dir="''${DIMENSION_HUB_LOG_DIR:-/var/log/dimension-hub}"
    config_dir="''${DIMENSION_HUB_CONFIG_DIR:-/etc/dimension/hub}"
    id_file="$state_dir/id"
    log_file="$log_dir/hub.log"

    mkdir -p "$state_dir" "$log_dir" "$config_dir"

    log() {
      timestamp="$(${pkgs.coreutils}/bin/date -Is)"
      ${pkgs.coreutils}/bin/printf '%s dimension-hub: %s\n' "$timestamp" "$*" | ${pkgs.coreutils}/bin/tee -a "$log_file"
    }

    log "starting"

    if [ ! -s "$id_file" ]; then
      if [ -r /proc/sys/kernel/random/uuid ]; then
        read -r hub_id < /proc/sys/kernel/random/uuid
      else
        hub_id="dimension-hub-$(${pkgs.coreutils}/bin/date +%s)"
      fi

      ${pkgs.coreutils}/bin/printf '%s\n' "$hub_id" > "$id_file"
      ${pkgs.coreutils}/bin/chmod 0644 "$id_file"
      log "created hub id"
    else
      log "hub id exists"
    fi

    while true; do
      log "timestamp"
      ${pkgs.coreutils}/bin/sleep 60
    done
  '';
in
{
  options.dimension.hub.enable = lib.mkEnableOption "Dimension central hub foundation";

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d /var/lib/dimension-hub 0755 root root -"
      "d /var/log/dimension-hub 0755 root root -"
      "d /etc/dimension/hub 0755 root root -"
      "L+ /var/lib/dimension-hub/hub.sh - - - - ${hubScript}"
    ];

    systemd.services.dimension-hub = {
      description = "Dimension hub agent";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-tmpfiles-setup.service" ];

      serviceConfig = {
        Type = "simple";
        User = "root";
        ExecStart = "/var/lib/dimension-hub/hub.sh";
        Restart = "always";
        RestartSec = "5s";
        StandardOutput = "journal";
        StandardError = "journal";
      };
    };
  };
}
