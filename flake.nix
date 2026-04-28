{
  description = "Dimension - Personal NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = inputs@{ nixpkgs, ... }:
    let
      lib = nixpkgs.lib;

      mkNixosConfiguration = { system, modules }:
        lib.nixosSystem {
          inherit system modules;
          specialArgs = { inherit inputs; };
        };

      hosts = {
        main = {
          system = "x86_64-linux";
          modules = [
            ./hosts/main/configuration.nix
          ];
        };
        "desktop-test" = {
          system = "x86_64-linux";
          modules = [
            ./hosts/desktop-test/configuration.nix
          ];
        };
        installer = {
          system = "x86_64-linux";
          modules = [
            ./hosts/installer/configuration.nix
          ];
        };
      };
    in
    {
      nixosConfigurations = lib.mapAttrs (_: mkNixosConfiguration) hosts;

      nixosModules = {
        apps = import ./modules/apps;
        base = import ./modules/base;
        desktop = import ./modules/desktop;
        home-theatre = import ./modules/home-theatre;
        hub = import ./modules/hub;
        kde-config = import ./modules/kde-config;
        network = import ./modules/network;
        node = import ./modules/node;
        plymouth = import ./modules/plymouth;
        profiles = import ./modules/profiles;
        remote = import ./modules/remote;
        sddm = import ./modules/sddm;
        services = import ./modules/services;
        storage = import ./modules/storage;
        theme = import ./modules/theme;
        wireguard = import ./modules/wireguard;
      };
    };
}
