{ config, lib, pkgs, ... }:

let
  cfg = config.dimension;
  dimensionInstall = pkgs.writeShellScriptBin "dimension-install" ''
    set -eu

    host_id="''${1:-}"

    if [ "$#" -gt 1 ]; then
      printf 'usage: dimension-install [host-id]\n' >&2
      exit 1
    fi

    detect_repo_root() {
      if [ -n "''${DIMENSION_REPO_ROOT:-}" ] && [ -f "''${DIMENSION_REPO_ROOT}/flake.nix" ]; then
        printf '%s\n' "$DIMENSION_REPO_ROOT"
        return 0
      fi

      if repo_root="$(${pkgs.git}/bin/git rev-parse --show-toplevel 2>/dev/null)" && [ -f "$repo_root/flake.nix" ]; then
        printf '%s\n' "$repo_root"
        return 0
      fi

      if [ -f "$PWD/flake.nix" ]; then
        printf '%s\n' "$PWD"
        return 0
      fi

      return 1
    }

    prompt_nonempty() {
      prompt="$1"
      default_value="''${2:-}"

      while true; do
        if [ -n "$default_value" ]; then
          printf '%s [%s]: ' "$prompt" "$default_value" >&2
        else
          printf '%s: ' "$prompt" >&2
        fi

        read -r value

        if [ -z "$value" ]; then
          value="$default_value"
        fi

        if [ -n "$value" ]; then
          printf '%s\n' "$value"
          return 0
        fi
      done
    }

    choose_edition() {
      while true; do
        cat >&2 <<'EOF'
Choose a Dimension edition:
  1. desktop
  2. laptop
  3. server
  4. server-headless
  5. print-station
  6. gaming
  7. workstation
EOF
        printf 'Edition [1-7]: ' >&2
        read -r choice

        case "$choice" in
          1) printf 'desktop\n'; return 0 ;;
          2) printf 'laptop\n'; return 0 ;;
          3) printf 'server\n'; return 0 ;;
          4) printf 'server-headless\n'; return 0 ;;
          5) printf 'print-station\n'; return 0 ;;
          6) printf 'gaming\n'; return 0 ;;
          7) printf 'workstation\n'; return 0 ;;
        esac

        printf 'Invalid choice. Please select a number from 1 to 7.\n' >&2
      done
    }

    confirm_overwrite() {
      path="$1"

      while true; do
        printf 'File %s already exists. Overwrite? [y/N]: ' "$path" >&2
        read -r answer

        case "$answer" in
          y|Y|yes|YES) return 0 ;;
          n|N|no|NO|"") return 1 ;;
        esac
      done
    }

    validate_name() {
      value="$1"
      label="$2"

      case "$value" in
        *[!a-zA-Z0-9-]*|"")
          printf '%s must contain only letters, digits, and hyphens.\n' "$label" >&2
          exit 1
          ;;
      esac
    }

    if ! repo_root="$(detect_repo_root)"; then
      printf 'dimension-install must be run from the Dimension repository root,\n' >&2
      printf 'or with DIMENSION_REPO_ROOT pointing to it.\n' >&2
      exit 1
    fi

    if [ -z "$host_id" ]; then
      host_id="$(prompt_nonempty 'Host directory name' "")"
    fi

    host_name="$(prompt_nonempty 'Hostname' "$host_id")"
    main_user="$(prompt_nonempty 'Main local user' 'dimension')"
    edition="$(choose_edition)"
    state_version="$(prompt_nonempty 'system.stateVersion' '24.05')"

    validate_name "$host_id" 'Host directory name'
    validate_name "$host_name" 'Hostname'

    target_dir="$repo_root/hosts/$host_id"
    target_file="$target_dir/configuration.nix"

    ${pkgs.coreutils}/bin/mkdir -p "$target_dir"

    if [ -f "$target_file" ] && ! confirm_overwrite "$target_file"; then
      printf 'Aborted.\n' >&2
      exit 1
    fi

    cat > "$target_file" <<EOF
{ lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/base
    ../../modules/profiles
  ];

  dimension.edition = "''${edition}";
  dimension.mainUser = "''${main_user}";

  networking.hostName = "''${host_name}";

  boot.loader.grub = {
    enable = true;
    device = lib.mkDefault "nodev";
  };

  fileSystems."/" = {
    device = lib.mkDefault "/dev/disk/by-label/nixos";
    fsType = lib.mkDefault "ext4";
  };

  system.stateVersion = "''${state_version}";
}
EOF

    printf 'Generated %s\n' "$target_file"
    printf 'Next steps:\n'
    printf '  1. Run nixos-generate-config in the target system and copy hardware-configuration.nix.\n'
    printf '  2. Add the new host to flake.nix when ready.\n'
  '';
  dimensionWgKeygen = pkgs.writeShellScriptBin "dimension-wg-keygen" ''
    set -eu

    target_dir="''${1:-/etc/dimension/secrets}"
    private_key_file="$target_dir/wg-private-key"
    public_key_file="$target_dir/wg-public-key"

    if [ "$#" -gt 1 ]; then
      printf 'usage: dimension-wg-keygen [target-dir]\n' >&2
      exit 1
    fi

    if [ -e "$private_key_file" ] || [ -e "$public_key_file" ]; then
      printf 'Refusing to overwrite existing WireGuard key files in %s\n' "$target_dir" >&2
      exit 1
    fi

    ${pkgs.coreutils}/bin/install -d -m 0700 "$target_dir"
    umask 077

    ${pkgs.wireguard-tools}/bin/wg genkey > "$private_key_file"
    ${pkgs.wireguard-tools}/bin/wg pubkey < "$private_key_file" > "$public_key_file"

    ${pkgs.coreutils}/bin/chmod 0600 "$private_key_file"
    ${pkgs.coreutils}/bin/chmod 0644 "$public_key_file"

    printf 'Generated:\n'
    printf '  private: %s\n' "$private_key_file"
    printf '  public:  %s\n' "$public_key_file"
    printf '\n'
    printf 'Host snippet:\n'
    printf '  dimension.wireguard = {\n'
    printf '    enable = true;\n'
    printf '    privateKeyFile = "%s";\n' "$private_key_file"
    printf '    address = "10.100.0.X/24";\n'
    printf '    openFirewall = true;\n'
    printf '  };\n'
  '';
in
{
  options.dimension.mainUser = lib.mkOption {
    type = lib.types.str;
    default = "dimension";
    example = "alice";
    description = "Main local user used by every Dimension machine.";
  };

  config = {
    # Shared configuration that should apply to every host in this flake.
    # Keep this file limited to cross-cutting defaults only.
    i18n.defaultLocale = "fr_FR.UTF-8";
    console.keyMap = "fr";
    time.timeZone = "Europe/Paris";

    users.users.${cfg.mainUser} = {
      isNormalUser = true;
      description = "Dimension main user";
      extraGroups = [ "wheel" ];
    };

    environment.systemPackages = with pkgs; [
      git
      curl
      wget
      vim
      nano
      htop
      btop
      unzip
      pciutils
      usbutils
      lsof
      tree
      dimensionInstall
      dimensionWgKeygen
    ];

    nix.settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };

    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };

    networking.firewall.enable = true;
    services.openssh.enable = false;
  };
}
