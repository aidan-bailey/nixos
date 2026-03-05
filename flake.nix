{
  description = "Aidan's NixOS config — modular flake (Wayland/Sway + libvirt)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-cachyos-kernel = {
      url = "github:xddxdd/nix-cachyos-kernel/release";
      # Must NOT follow nixpkgs — pins its own nixos-unstable-small
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    doom-flake.url = "path:./flakes/doom-emacs";
    nixarr.url = "github:rasmus-kirk/nixarr";
    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    harbour = {
      url = "github:ankerdata/harbour-3.2.0core";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      doom-flake,
      nix-cachyos-kernel,
      nixarr,
      antigravity-nix,
      harbour,
      sops-nix,
      ...
    }@inputs:
    let
      system = "x86_64-linux";

      commonModules = [
        ./modules/profile.nix
        doom-flake.nixosModules.default
        nixarr.nixosModules.default
        sops-nix.nixosModules.sops
        home-manager.nixosModules.home-manager
        {
          nixpkgs.config.allowUnfree = true;
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.sharedModules = [ sops-nix.homeManagerModules.sops ];
          home-manager.extraSpecialArgs = { inherit inputs system; };
          home-manager.users.aidanb = import ./home/users/aidanb;
        }
      ];

      # Module profiles — composable sets of system modules.
      # serverModules: minimal headless base (medesco)
      # desktopModules: full desktop with gaming, audio, Sway (nesco, fresco)
      serverModules = [
        ./modules/base.nix
        ./modules/user.nix
        ./modules/networking.nix
        ./modules/terminal.nix
        ./modules/mediaserver.nix
        ./modules/secrets.nix
      ];

      desktopModules = serverModules ++ [
        ./modules/kernel/cachyos.nix
        ./modules/sway.nix
        ./modules/audio.nix
        ./modules/bluetooth.nix
        ./modules/gaming.nix
        ./modules/nix-ld.nix
        ./modules/virtualisation.nix
        ./modules/power.nix
      ];

      # mkHost: Takes a host config and a module profile, merges with
      # commonModules (flake inputs), and builds a NixOS system.
      mkHost =
        { hostConfig, profile }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [ hostConfig ] ++ profile ++ commonModules;
          specialArgs = { inherit inputs system; };
        };
    in
    {
      nixosConfigurations = {
        nesco = mkHost {
          hostConfig = ./hosts/nesco/configuration.nix;
          profile = desktopModules;
        };
        fresco = mkHost {
          hostConfig = ./hosts/fresco/configuration.nix;
          profile = desktopModules;
        };
        medesco = mkHost {
          hostConfig = ./hosts/medesco/configuration.nix;
          profile = serverModules;
        };
      };
    };
}
