{
  description = "Aidan's NixOS configuration — Wayland/Sway flake setup";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Optional: add home-manager, flake-utils, etc later if desired
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations.nesco = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
      ];

      specialArgs = {
        inherit inputs;
      };
    };
  };
}
