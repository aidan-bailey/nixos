{
  config,
  lib,
  pkgs,
  ...
}:

{
  # CachyOS kernel configuration
  boot.kernelPackages = pkgs.linuxPackages_cachyos;
}

