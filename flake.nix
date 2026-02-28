{
  description = "Aidan's NixOS config — modular flake (Wayland/Sway + libvirt)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    chaotic = {
      url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
      inputs.nixpkgs.follows = "nixpkgs";
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
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      doom-flake,
      chaotic,
      nixarr,
      antigravity-nix,
      harbour,
      ...
    }@inputs:
    let
      system = "x86_64-linux";

      commonModules = [
        doom-flake.nixosModules.default
        chaotic.nixosModules.default
        nixarr.nixosModules.default
        home-manager.nixosModules.home-manager
        {
          nixpkgs.config.allowUnfree = true;
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
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
      mkHost = { hostConfig, profile }: nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [ hostConfig ] ++ profile ++ commonModules;
        specialArgs = { inherit inputs system; };
      };
    in
    {
      nixosConfigurations = {
        nesco = mkHost { hostConfig = ./hosts/nesco/configuration.nix; profile = desktopModules; };
        fresco = mkHost { hostConfig = ./hosts/fresco/configuration.nix; profile = desktopModules; };
        medesco = mkHost { hostConfig = ./hosts/medesco/configuration.nix; profile = serverModules; };
      };
    };
}
