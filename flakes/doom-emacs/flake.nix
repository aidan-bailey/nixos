{
  description = "Reusable Doom Emacs flake (PGTK + native-comp + built-in config)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    emacs-overlay.url = "github:nix-community/emacs-overlay";
    doom-emacs.url = "github:nix-community/nix-doom-emacs";
  };

  outputs =
    {
      self,
      nixpkgs,
      emacs-overlay,
      doom-emacs,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ emacs-overlay.overlay ];
      };
    in
    {

      nixosModules.default =
        { config, lib, ... }:
        {
          imports = [ doom-emacs.nixosModules.default ];

          programs.doom-emacs = {
            enable = true;
            emacsPackage = pkgs.emacs-pgtk.override {
              withNativeCompilation = true;
            };
            doomPrivateDir = ./doom-config;
          };
        };

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

      packages.${system}.doom = pkgs.callPackage doom-emacs.packages.default {
        emacsPackage = pkgs.emacs-pgtk.override {
          withNativeCompilation = true;
        };
        doomPrivateDir = ./doom-config;
      };
    };
}
