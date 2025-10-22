{
  description = "Aidan's NixOS config — modular flake (Wayland/Sway + libvirt)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    doom-flake.url = "path:./flakes/doom-emacs";
  };

  outputs =
    {
      self,
      nixpkgs,
      doom-flake,
      chaotic,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      nixosConfigurations.nesco = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/nesco/configuration.nix
          doom-flake.nixosModules.default
          chaotic.nixosModules.default
          {
            nixpkgs.config.allowUnfree = true;
          }
        ];
        specialArgs = { inherit inputs system; };
      };
    };
}
