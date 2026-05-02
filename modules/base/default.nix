{ config, lib, pkgs, ... }:

let
  cfg = config.dimension;
  dimensionInstall = pkgs.writeShellScriptBin "dimension-install" ''
    set -u

    SOURCE_FLAKE="/etc/dimension/flake"
    if [ -n "''${DIMENSION_SOURCE_FLAKE:-}" ]; then
      SOURCE_FLAKE="$DIMENSION_SOURCE_FLAKE"
    fi

    WORK_FLAKE="/tmp/dimension-install-flake"
    LOG_DIR="/tmp/dimension-install-logs"
    DISK=""
    EDITION=""
    HOSTNAME=""
    USERNAME=""
    PASSWORD=""

    print_banner() {
      clear

      if [ -r /etc/dimension-banner ]; then
        cat /etc/dimension-banner
        return 0
      fi

      cols="$(tput cols 2>/dev/null || printf '80')"
      cat <<'EOF_BANNER' | while IFS= read -r line; do
 ____  _                              _
|  _ \(_)_ __ ___   ___ _ __  ___(_) ___  _ __
| | | | | '_ ` _ \ / _ \ '_ \/ __| |/ _ \| '_ \
| |_| | | | | | | |  __/ | | \__ \ | (_) | | | |
|____/|_|_| |_| |_|\___|_| |_|___/_|\___/|_| |_|

                     Dimension OS
EOF_BANNER
        line_len="''${#line}"
        if [ "$cols" -gt "$line_len" ]; then
          pad=$(( (cols - line_len) / 2 ))
        else
          pad=0
        fi
        printf '%*s%s\n' "$pad" "" "$line"
      done
    }

    show_error() {
      message="$1"

      if command -v whiptail >/dev/null 2>&1; then
        whiptail --title "Erreur" --msgbox "$message" 18 78 || true
      else
        printf '%s\n' "$message" >&2
      fi
    }

    fail() {
      show_error "$1"
      exit 1
    }

    require_command() {
      name="$1"
      if ! command -v "$name" >/dev/null 2>&1; then
        fail "Commande requise introuvable: $name"
      fi
    }

    run_critical() {
      title="$1"
      shift

      mkdir -p "$LOG_DIR"
      step_log="$LOG_DIR/$(printf '%s' "$title" | tr ' /' '--').log"

      print_banner
      printf '\n%s\n' "$title"
      printf 'Journal: %s\n\n' "$step_log"

      "$@" 2>&1 | tee "$step_log"
      status="''${PIPESTATUS[0]}"

      if [ "$status" -ne 0 ]; then
        tail_msg="$(tail -n 24 "$step_log" 2>/dev/null || true)"
        fail "$title a echoue.\n\n$tail_msg"
      fi
    }

    validate_hostname() {
      value="$1"

      case "$value" in
        ""|[-]*|*-|*[!a-zA-Z0-9-]*)
          fail "Le hostname doit contenir uniquement lettres, chiffres et tirets, sans tiret au debut ou a la fin."
          ;;
      esac

      if [ "''${#value}" -gt 63 ]; then
        fail "Le hostname doit faire 63 caracteres maximum."
      fi
    }

    validate_username() {
      value="$1"

      case "$value" in
        ""|[0-9-]*|*[!a-z0-9_-]*)
          fail "Le nom d'utilisateur doit commencer par une lettre ou _, puis contenir seulement minuscules, chiffres, _ ou -."
          ;;
      esac

      if [ "''${#value}" -gt 32 ]; then
        fail "Le nom d'utilisateur doit faire 32 caracteres maximum."
      fi
    }

    select_disk() {
      while true; do
        menu=()

        while read -r name size model; do
          [ -n "$name" ] || continue

          case "$name" in
            loop*) continue ;;
          esac

          model="''${model:-Disque}"
          menu+=( "/dev/$name" "$size $model" )
        done < <(lsblk -d -o NAME,SIZE,MODEL --noheadings | grep -v loop || true)

        if [ "''${#menu[@]}" -eq 0 ]; then
          fail "Aucun disque installable detecte."
        fi

        if ! DISK="$(whiptail --title "Dimension OS" --menu "Selectionner le disque d'installation" 20 78 10 "''${menu[@]}" 3>&1 1>&2 2>&3)"; then
          exit 0
        fi

        if whiptail --title "Confirmation" --yesno "Tout le contenu de $DISK sera efface. Confirmer ?" 10 70; then
          return 0
        fi
      done
    }

    select_edition() {
      if ! EDITION="$(whiptail --title "Edition" --menu "Selectionner l'edition Dimension OS" 20 78 8 \
        desktop "Bureau Plasma" \
        laptop "Portable" \
        gaming "Jeu" \
        workstation "Station de travail" \
        print-station "Impression" \
        home-theatre "Home theatre" \
        server "Serveur" \
        server-headless "Serveur sans interface" \
        3>&1 1>&2 2>&3)"; then
        exit 0
      fi
    }

    prompt_input() {
      title="$1"
      prompt="$2"
      default_value="$3"

      while true; do
        if ! value="$(whiptail --title "$title" --inputbox "$prompt" 10 70 "$default_value" 3>&1 1>&2 2>&3)"; then
          exit 0
        fi

        if [ -n "$value" ]; then
          printf '%s\n' "$value"
          return 0
        fi

        whiptail --title "$title" --msgbox "Cette valeur est requise." 8 60
      done
    }

    prompt_password() {
      while true; do
        if ! password="$(whiptail --title "Mot de passe" --passwordbox "Mot de passe pour $USERNAME" 10 70 3>&1 1>&2 2>&3)"; then
          exit 0
        fi

        if ! confirm="$(whiptail --title "Confirmation" --passwordbox "Confirmer le mot de passe" 10 70 3>&1 1>&2 2>&3)"; then
          exit 0
        fi

        if [ -z "$password" ]; then
          whiptail --title "Mot de passe" --msgbox "Le mot de passe ne peut pas etre vide." 8 66
        elif [ "$password" != "$confirm" ]; then
          whiptail --title "Mot de passe" --msgbox "Les mots de passe ne correspondent pas." 8 66
        else
          PASSWORD="$password"
          return 0
        fi
      done
    }

    collect_machine_info() {
      HOSTNAME="$(prompt_input "Machine" "Hostname" "dimension")"
      validate_hostname "$HOSTNAME"

      USERNAME="$(prompt_input "Utilisateur" "Nom d'utilisateur principal" "dimension")"
      validate_username "$USERNAME"

      prompt_password
    }

    confirm_summary() {
      summary="Disque: $DISK
Edition: $EDITION
Hostname: $HOSTNAME
Utilisateur: $USERNAME"

      whiptail --title "Resume" --yesno "$summary" 14 72
    }

    collect_choices() {
      while true; do
        select_disk
        select_edition
        collect_machine_info

        if confirm_summary; then
          return 0
        fi
      done
    }

    copy_flake_tree() {
      target="$1"

      case "$target" in
        "$WORK_FLAKE"|/mnt/etc/dimension) ;;
        *) fail "Cible interne refusee: $target" ;;
      esac

      if [ ! -d "$SOURCE_FLAKE" ] || [ ! -f "$SOURCE_FLAKE/flake.nix" ]; then
        fail "Flake Dimension introuvable: $SOURCE_FLAKE"
      fi

      rm -rf -- "$target"
      mkdir -p "$target" || fail "Impossible de creer $target"
      cp -aL "$SOURCE_FLAKE/." "$target/" || fail "Impossible de copier le flake Dimension vers $target"
      chmod -R u+w "$target" 2>/dev/null || true
    }

    write_host_configuration() {
      flake_dir="$1"
      host_dir="$flake_dir/hosts/$HOSTNAME"

      mkdir -p "$host_dir" || fail "Impossible de creer $host_dir"

      cat > "$host_dir/configuration.nix" <<EOF_HOST
{ lib, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/base
    ../../modules/profiles
    ../../modules/installer/disko-simple.nix
  ];

  dimension.edition = "$EDITION";
  dimension.mainUser = "$USERNAME";
  dimension.installer.disk.device = "$DISK";

  networking.hostName = "$HOSTNAME";

  system.stateVersion = "24.05";
}
EOF_HOST

      if [ ! -f "$host_dir/hardware-configuration.nix" ]; then
        cat > "$host_dir/hardware-configuration.nix" <<'EOF_HW'
{ ... }:
{
}
EOF_HW
      fi
    }

    prepare_work_flake() {
      copy_flake_tree "$WORK_FLAKE"
      write_host_configuration "$WORK_FLAKE"
    }

    generate_standalone_disko_config() {
      target="/tmp/disko-$HOSTNAME.nix"

      cat > "$target" <<EOF_DISKO
{
  disko.devices.disk.main = {
    type = "disk";
    device = "$DISK";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          type = "EF00";
          size = "512M";
          priority = 1;
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
}
EOF_DISKO

      printf '%s\n' "$target"
    }

    run_disko_from_flake() {
      disko --mode destroy,format,mount --yes-wipe-all-disks --flake "$WORK_FLAKE#$HOSTNAME" \
        || disko --mode disko --flake "$WORK_FLAKE#$HOSTNAME"
    }

    run_disko_fallback() {
      disko_file="$(generate_standalone_disko_config)"

      cd "$WORK_FLAKE" \
        && nix run .#disko -- --mode destroy,format,mount --yes-wipe-all-disks "$disko_file" \
        || nix run .#disko -- --mode disko "$disko_file"
    }

    partition_disk() {
      if command -v disko >/dev/null 2>&1; then
        run_disko_from_flake
      else
        run_disko_fallback
      fi
    }

    prepare_installed_flake() {
      copy_flake_tree /mnt/etc/dimension
      write_host_configuration /mnt/etc/dimension

      if [ ! -f /mnt/etc/nixos/hardware-configuration.nix ]; then
        fail "hardware-configuration.nix n'a pas ete genere."
      fi

      cp /mnt/etc/nixos/hardware-configuration.nix \
        "/mnt/etc/dimension/hosts/$HOSTNAME/hardware-configuration.nix" \
        || fail "Impossible de copier hardware-configuration.nix dans le flake installe."
    }

    set_user_password() {
      mkdir -p "$LOG_DIR"
      step_log="$LOG_DIR/password.log"

      print_banner
      printf '\nConfiguration du mot de passe utilisateur\n'
      printf 'Journal: %s\n\n' "$step_log"

      if printf '%s:%s\n' "$USERNAME" "$PASSWORD" | nixos-enter --root /mnt -c 'chpasswd' > "$step_log" 2>&1; then
        PASSWORD=""
        return 0
      fi

      tail_msg="$(tail -n 24 "$step_log" 2>/dev/null || true)"
      fail "La configuration du mot de passe a echoue.\n\n$tail_msg"
    }

    finish_install() {
      whiptail --title "Dimension OS" --msgbox "Installation terminee. Retirer le support et redemarrer." 10 70

      if whiptail --title "Redemarrage" --yesno "Redemarrer maintenant ?" 8 60; then
        reboot
      fi
    }

    main() {
      require_command whiptail
      require_command lsblk
      require_command nixos-generate-config
      require_command nixos-install
      require_command nixos-enter

      if [ "$#" -gt 0 ]; then
        fail "usage: dimension-install"
      fi

      print_banner
      whiptail --title "Dimension OS" --msgbox "Bienvenue dans l'installateur Dimension OS" 10 60

      collect_choices
      prepare_work_flake

      # Partition and mount first; hardware config is generated before nixos-install.
      run_critical "Partitionnement du disque" partition_disk
      run_critical "Generation hardware-configuration" nixos-generate-config --root /mnt --no-filesystems
      prepare_installed_flake
      run_critical "Installation Dimension OS" nixos-install --root /mnt --flake "/mnt/etc/dimension#$HOSTNAME" --no-root-passwd
      set_user_password
      finish_install
    }

    main "$@"
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

    # Determinate Nix 2.33 warns on the generated NixOS option docs because
    # the derivation references the nixpkgs source path without a string
    # context. Avoid that fragile build path in the installer/system closure.
    documentation.nixos.enable = false;
  };
}
