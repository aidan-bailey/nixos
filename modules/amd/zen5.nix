{
  config,
  lib,
  pkgs,
  ...
}:

{
 
   nixpkgs.hostPlatform = {
    system = "x86_64-linux";
    gcc.arch = "znver5";
    gcc.tune = "znver5";
  };

  environment.sessionVariables = {
    RUSTFLAGS = "-C target-cpu=znver5 -C link-arg=-flto";
    GOAMD64 = "v4";
  };

  boot.kernelPatches = [
    {
      name = "znver5-optimization";
      patch = null;
      extraConfig = ''
        KCFLAGS="-march=znver5 -mtune=znver5 -O3 -pipe"
      '';
    }
  ];

}

