{
  description = "Aidan's NixOS config — modular flake (Wayland/Sway + libvirt)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    doom-flake.url = "path:./flakes/doom-emacs";
  };

  outputs =
    {
      self,
      nixpkgs,
      doom-flake,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
      };
    in
    {
      nixosConfigurations = {
        nesco = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/nesco/configuration.nix
            doom-flake.nixosModules.default
            {
              nixpkgs = {
                config.allowUnfree = true;
              };
            }
          ];

          specialArgs = { inherit inputs; };
        };
      };

    };
}
