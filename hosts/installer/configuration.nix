{ inputs, lib, pkgs, ... }:

let
  bootSplash = ../../assets/wallpapers/dimension-boot-splash.png;
  grubTheme = pkgs.runCommand "dimension-installer-grub-theme" {} ''
    mkdir -p "$out"
    chmod 755 "$out"
    cp -r ${pkgs.nixos-grub2-theme}/* "$out/"
    chmod 755 "$out"
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
  border_color = #0078D7
  bg_color = #001a31
  fg_color = #0078D7
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
  '';
in

{
  imports = [
    "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-plasma6.nix"
    ../../modules/base
    ../../modules/profiles
  ];

  dimension = {
    edition = "desktop";
    desktop.enable = lib.mkForce false;
    hub.enable = lib.mkForce false;
    node.enable = lib.mkForce false;
    remote.enable = lib.mkForce false;
    storage.enable = lib.mkForce false;
    wireguard.enable = lib.mkForce false;
  };

  networking.hostName = "dimension-installer";

  isoImage = {
    efiSplashImage = bootSplash;
    grubTheme = grubTheme;
    splashImage = bootSplash;
  };

  system.stateVersion = "24.05";
}
