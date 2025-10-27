{
  description = "Reusable NixOS module for system-wide ccache in Nix builds";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    {
      nixosModules.ccache =
        {
          lib,
          pkgs,
          config,
          ...
        }:
        {

          options.ccache = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Enable system-wide ccache for Nix builds.";
            };

            cacheDir = lib.mkOption {
              type = lib.types.path;
              default = "/var/cache/ccache";
              description = "Directory for persistent ccache cache data.";
            };
          };

          config = lib.mkIf config.ccache.enable {

            environment.systemPackages = [
              pkgs.ccache
            ];

            programs.ccache.enable = true;
            programs.ccache.cacheDir = config.ccache.cacheDir;

            # Allow the cache dir inside the sandbox
            nix.settings.extra-sandbox-paths = [ config.ccache.cacheDir ];

            # Environment variables recognized by ccache
            environment.variables = {
              CCACHE_DIR = config.ccache.cacheDir;
              CCACHE_COMPILERCHECK = "content";
              CCACHE_COMPRESS = "1";
              CCACHE_COMPRESSLEVEL = "6";
              CCACHE_MAXSIZE = "20G";
              CCACHE_SLOPPINESS = "time_macros,file_macro,include_file_mtime";
              CCACHE_UMASK = "007";

              # Tell compilers to go through ccache
              CC = "${pkgs.ccache}/bin/ccache gcc";
              CXX = "${pkgs.ccache}/bin/ccache g++";
              # optionally for clang
              # CLANG = "${pkgs.ccache}/bin/ccache clang";
            };

            # Ensure /var/cache/ccache exists and has correct permissions
            systemd.tmpfiles.rules = [
              "d ${config.ccache.cacheDir} 0770 root nixbld -"
            ];

            # Optional: mount it as tmpfs for speed
            # fileSystems."/var/cache/ccache" = {
            #   device = "none";
            #   fsType = "tmpfs";
            #   options = [ "mode=0770" "size=8G" ];
            # };
          };
        };
    };
}
