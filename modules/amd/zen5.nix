{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Zen5-specific kernel optimizations
  boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.linux_cachyos.overrideAttrs (old: {
    makeFlags = old.makeFlags or [] ++ [
      "KCFLAGS=-march=znver5 -mtune=znver5 -O3 -pipe"
    ];
  }));
  
  # Alternative Zen5 optimization approaches (commented for reference)
  #boot.kernelPackages = pkgs.linuxPackages_cachyos; #.cachyOverride { mArch = "ZEN4"; };
  #boot.kernelPatches = [
  #  {
  #    name = "znver5-optimization";
  #    patch = null;
  #    extraConfig = ''
  #      KCFLAGS="-march=znver5 -mtune=znver5 -O3 -pipe -fomit-frame-pointer"
  #    '';
  #  }
  #];

}

