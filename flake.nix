{
  description = "Dimension - Personal NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ disko, home-manager, nixpkgs, plasma-manager, ... }:
    let
      lib = nixpkgs.lib;

      mkNixosConfiguration = { system, modules }:
        lib.nixosSystem {
          inherit system;
          modules = [
            disko.nixosModules.disko
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = { inherit inputs; };
              };
            }
          ] ++ modules;
          specialArgs = { inherit inputs home-manager plasma-manager; };
        };

      hostEntries =
        lib.filterAttrs
          (name: type:
            type == "directory"
            && builtins.pathExists (./hosts + "/${name}/configuration.nix"))
          (builtins.readDir ./hosts);

      hosts = lib.mapAttrs
        (name: _:
          let
            hostPath = ./hosts + "/${name}";
          in
          {
            system = "x86_64-linux";
            modules = [
              (hostPath + "/configuration.nix")
            ];
          })
        hostEntries;
    in
    {
      nixosConfigurations = lib.mapAttrs (_: mkNixosConfiguration) hosts;

      packages.x86_64-linux = {
        disko = disko.packages.x86_64-linux.disko;
      };

      nixosModules = {
        apps = import ./modules/apps;
        base = import ./modules/base;
        desktop = import ./modules/desktop;
        dimension-settings = import ./modules/dimension-settings;
        home-theatre = import ./modules/home-theatre;
        hub = import ./modules/hub;
        installer-disko-simple = import ./modules/installer/disko-simple.nix;
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
