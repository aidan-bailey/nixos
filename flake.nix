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
    #ccache-flake.url = "path:./flakes/ccache";
    #gcc-lto-pgo.url = "path:./flakes/gcc-lto-pgo";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      doom-flake,
      #ccache-flake,
      chaotic,
      nixarr,
      antigravity-nix,
      harbour,
      #gcc-lto-pgo,
      ...
    }@inputs:
    let
      system = "x86_64-linux";

      commonModules = [
        #ccache-flake.nixosModules.ccache
        doom-flake.nixosModules.default
        chaotic.nixosModules.default
        nixarr.nixosModules.default
        #gcc-lto-pgo.nixosModules.default
        home-manager.nixosModules.home-manager
        {
          nixpkgs.config.allowUnfree = true;
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs system; };
          home-manager.users.aidanb = import ./home/users/aidanb;
        }
      ];

      mkHost = hostConfig: nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [ hostConfig ] ++ commonModules;
        specialArgs = { inherit inputs system; };
      };
    in
    {
      nixosConfigurations = {
        nesco = mkHost ./hosts/nesco/configuration.nix;
        fresco = mkHost ./hosts/fresco/configuration.nix;
        medesco = mkHost ./hosts/medesco/configuration.nix;
      };
    };
}
