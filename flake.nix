{
  description = "Aidan's NixOS config — modular flake (Wayland/Sway + libvirt)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
      emacs-overlay,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ emacs-overlay.overlay ];
      };
    in
    {
      nixosConfigurations = {
        nesco = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/nesco/configuration.nix

            {
              nixpkgs = {
                config.allowUnfree = true;
                overlays = [ inputs.emacs-overlay.overlay ];
              };
            }
          ];

          specialArgs = { inherit inputs; };
        };
      };

    };
}
