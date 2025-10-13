{
  description = "Aidan's NixOS config — modular flake (Wayland/Sway + libvirt)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ ];
      };
    in
    {
      nixosConfigurations = {
        nesco = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./hosts/nesco/configuration.nix
          ];
          specialArgs = { inherit inputs pkgs; };
        };
      };
    };
}
