# flakes/doom-emacs/flake.nix
{
  description = "Reusable Doom Emacs flake (PGTK + native-comp + built-in config)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      self,
      inputs,
      nixpkgs,
      doom-emacs,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          (pkgs.doomEmacs {
            doomDir = inputs.doom-config;
            # If you stored your Doom configuration in the same flake, use
            #   doomDir = ./path/to/doom/config;
            # instead.
            doomLocalDir = "~/.local/share/nix-doom";
          })
        ];
      };
    in
    {

      homeManagerModules.default =
        { config, lib, ... }:
        {
          imports = [ doom-emacs.hmModule ];

          programs.doom-emacs = {
            enable = true;
            emacsPackage = pkgs.emacs-pgtk.override {
              withNativeCompilation = true;
            };
            doomPrivateDir = ./doom-config;
          };
        };

    };
}
