{ inputs, lib, pkgs, ... }:

let
  bootSplash = ../../assets/wallpapers/dimension-boot-splash.png;
  diskoPackage = inputs.disko.packages.${pkgs.stdenv.hostPlatform.system}.disko;

  grubTheme = pkgs.runCommand "dimension-installer-grub-theme" {} ''
    mkdir -p "$out"

    cp -r ${pkgs.nixos-grub2-theme}/. "$out/"
    chmod -R u+w "$out"

    cp ${bootSplash} "$out/background.png"
    chmod 644 "$out/background.png"

    cat > "$out/theme.txt" <<'EOF'
title-text: ""
desktop-image: "background.png"
message-font: "DejaVu Regular"
message-color: "#E8F0F8"
terminal-font: "Unifont Regular"
terminal-box: "terminal_*.png"

+ progress_bar {
  id = "__timeout__"
  top = 95%-32
  left = 50%-25%
  height = 32
  width = 50%
  show_text = true
  text = "@TIMEOUT_NOTIFICATION_MIDDLE@"
  border_color = "#0078D7"
  bg_color = "#001a31"
  fg_color = "#0078D7"
}

+ boot_menu {
  left = 50%-400
  width = 800
  top = 12%
  height = 72%
  item_font = "DejaVu Regular"
  item_color = "#ffffff"
  item_height = 40
  item_icon_space = 12
  item_spacing = 0
  item_padding = 0
  selected_item_font = "DejaVu Regular"
  selected_item_color = "#000F1F"
  selected_item_pixmap_style = "select_*.png"
  icon_height = 32
  icon_width = 42
  scrollbar = false
  menu_pixmap_style = "boot_menu_*.png"
}
EOF

    chmod -R 755 "$out"
    chmod 644 "$out/background.png" "$out/theme.txt"
  '';

  rootBashrc = pkgs.writeText "dimension-root-bashrc" ''
    if [ "$(id -u)" = "0" ] && [ "$(tty)" = "/dev/tty1" ]; then
      clear
      [ -r /etc/dimension-banner ] && cat /etc/dimension-banner
      exec dimension-install
    fi
  '';
in

{
  imports = [
    "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
    ../../modules/base
    ../../modules/profiles
  ];

  dimension = {
    edition = "server-headless";
    apps.enable = lib.mkForce false;
    desktop.enable = lib.mkForce false;
    kde.enable = lib.mkForce false;
    network.enable = true;
    plymouth.enable = true;
    sddm.enable = lib.mkForce false;
    theme.enable = lib.mkForce false;
    hub.enable = lib.mkForce false;
    node.enable = lib.mkForce false;
    remote.enable = lib.mkForce false;
    storage.enable = lib.mkForce false;
    wireguard.enable = lib.mkForce false;
  };

  networking.hostName = "dimension-installer";

  system.nixos = {
    distroId = "dimension";
    distroName = "Dimension OS";
    variant_id = "installer";
    variantName = "Dimension OS Installer";
  };

  services.getty = {
    autologinUser = lib.mkForce "root";
    greetingLine = lib.mkForce "";
    helpLine = lib.mkForce "";
  };

  users.motd = lib.mkForce "";

  boot = {
    consoleLogLevel = 0;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "splash"
      "loglevel=0"
      "udev.log_level=0"
    ];
  };

  environment = {
    systemPackages = with pkgs; [
      newt
      parted
      util-linux
      diskoPackage
    ];

    etc = {
      "dimension/flake".source = ../../.;
      "issue".text = "";
      "dimension-banner".text = ''
         ____  _                              _
        |  _ \(_)_ __ ___   ___ _ __  ___(_) ___  _ __
        | | | | | '_ ` _ \ / _ \ '_ \/ __| |/ _ \| '_ \
        | |_| | | | | | | |  __/ | | \__ \ | (_) | | | |
        |____/|_|_| |_| |_|\___|_| |_|___/_|\___/|_| |_|

                         Dimension OS
      '';
    };

    interactiveShellInit = ''
      PS1='\[\e[1;34m\]Dimension\[\e[0m\] \w # '

      if [ "$(id -u)" = "0" ] && [ "$(tty)" = "/dev/tty1" ] && [ -z "''${DIMENSION_INSTALLER_STARTED:-}" ]; then
        export DIMENSION_INSTALLER_STARTED=1
        clear
        [ -r /etc/dimension-banner ] && cat /etc/dimension-banner
        exec dimension-install
      fi
    '';
  };

  system.activationScripts.dimensionRootBashrc.text = ''
    ${pkgs.coreutils}/bin/install -D -m 0644 ${rootBashrc} /root/.bashrc
  '';

  isoImage = {
    appendToMenuLabel = " Installer";
    grubTheme = grubTheme;
    splashImage = bootSplash;
    volumeID = "DIMENSION_INSTALLER";
  };

  image = {
    baseName = lib.mkForce "dimension-os-installer";
    fileName = lib.mkForce "dimension-os-installer.iso";
  };

  system.stateVersion = "24.05";
}
