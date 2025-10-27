{
  config,
  lib,
  pkgs,
  ...
}:

{

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

