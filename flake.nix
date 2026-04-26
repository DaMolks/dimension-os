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
      };
    in
    {
      nixosConfigurations = lib.mapAttrs (_: mkNixosConfiguration) hosts;

      nixosModules = {
        base = import ./modules/base;
        desktop = import ./modules/desktop;
        hub = import ./modules/hub;
        network = import ./modules/network;
        node = import ./modules/node;
        profiles = import ./modules/profiles;
        remote = import ./modules/remote;
        services = import ./modules/services;
        storage = import ./modules/storage;
      };
    };
}
