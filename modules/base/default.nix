{ config, lib, pkgs, ... }:

let
  cfg = config.dimension;
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
