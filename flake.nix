{
  description = "Aidan's NixOS config — modular flake (Wayland/Sway + libvirt)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    doom-flake.url = "path:./flakes/doom-emacs";
    nixarr.url = "github:rasmus-kirk/nixarr";
    #ccache-flake.url = "path:./flakes/ccache";
    #gcc-lto-pgo.url = "path:./flakes/gcc-lto-pgo";
  };

  outputs =
    {
      self,
      nixpkgs,
      doom-flake,
      #ccache-flake,
      chaotic,
      nixarr,
      #gcc-lto-pgo,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
      };
    in
    {
      nixosConfigurations.nesco = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/nesco/configuration.nix
          #ccache-flake.nixosModules.ccache
          doom-flake.nixosModules.default
          chaotic.nixosModules.default
          nixarr.nixosModules.default
          #gcc-lto-pgo.nixosModules.default
          {
            nixpkgs.config.allowUnfree = true;
          }
        ];
        specialArgs = { inherit inputs system; };
      };
    };
}
