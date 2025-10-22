{
  description = "Reusable Doom Emacs flake (PGTK + native-comp + built-in config)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-doom-emacs-unstraightened.url = "github:marienz/nix-doom-emacs-unstraightened";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      ...
    }:
    {
      nixosModules.default =
        {
          system ? "x86_64-linux",
          ...
        }:
        let
          doomPkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = [ inputs.nix-doom-emacs-unstraightened.overlays.default ];
          };
        in
        {
          environment.systemPackages = [
            (doomPkgs.emacsWithDoom {
              doomDir = ./doom.d;
              doomLocalDir = "~/.local/share/nix-doom";
              emacs = doomPkgs.emacs-pgtk.override {
                withNativeCompilation = true;
              };
              extraPackages = epkgs: [
                #doomPkgs.shellcheck
                #doomPkgs.ripgrep
                #doomPkgs.shfmt
                #doomPkgs.fd
                #python3Packages.black
                #python3Packages.pyflakes
                #python3Packages.isort
                #python3Packages.pytest
              ];
            })
            doomPkgs.shellcheck
            doomPkgs.ripgrep
            doomPkgs.shfmt
            doomPkgs.fd
            doomPkgs.python313Packages.black
            doomPkgs.python313Packages.pyflakes
            doomPkgs.python313Packages.isort
            doomPkgs.python313Packages.pytest
          ];
        };
    };
}
