{
  description = "Custom GCC 13 built with LTO + PGO and fortify disabled";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ];
    in
    {

      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          gcc-lto-pgo = pkgs.gcc13.overrideAttrs (old: {
            name = "gcc13-lto-pgo";

            BOOT_CFLAGS = "-O2 -pipe -flto=jobserver";
            LDFLAGS = "-flto=jobserver";

            configureFlags = old.configureFlags ++ [
              "--enable-lto"
              "--enable-bootstrap"
              "--enable-linker-build-id"
              "--enable-plugin"
            ];

            makeFlags = [ "profiledbootstrap" ];
            hardeningDisable = [ "fortify" ];

            meta = old.meta // {
              description = "GCC 13 built with LTO + PGO (FORTIFY disabled)";
              longDescription = ''
                A GCC 13 build optimized with both Link-Time Optimization (LTO)
                and Profile-Guided Optimization (PGO), with FORTIFY_SOURCE disabled.
                Designed for faster compilation and smaller binaries at the cost of
                longer build times.
              '';
            };
          });
        }
      );

      # -------- NixOS module to replace system GCC -----------------------------
      nixosModules.default =
        { pkgs, ... }:
        {
          nixpkgs.overlays = [
            (final: prev: {
              gcc = self.packages.${prev.system}.gcc-lto-pgo;
              stdenv = prev.overrideCC prev.stdenv final.gcc;
            })
          ];
        };

    };

}
