{
  config,
  lib,
  pkgs,
  ...
}:

{

  imports = [
    ./cpu.nix
  ];

  nixpkgs.hostPlatform = {
    system = "x86_64-linux";
    gcc.arch = "znver4";
    gcc.tune = "znver4";
  };

  environment.sessionVariables = {
    RUSTFLAGS = "-C target-cpu=znver4 -C link-arg=-flto";
    GOAMD64 = "v4";
  };

  boot.kernelPatches = [
    {
      name = "znver4-optimization";
      patch = null;
      extraConfig = ''
        KCFLAGS="-march=znver4 -mtune=znver4 -O2 -pipe"
      '';
    }
  ];

}
