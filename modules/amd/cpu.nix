{
  config,
  lib,
  pkgs,
  ...
}:

{

  boot.extraModprobeConfig = "options kvm_amd sev=1";
  hardware.cpu.amd.updateMicrocode = true;
  boot.kernelParams = [
    "amd_pstate=active"
    "amdgpu.dc=1"
    "amdgpu.ppfeaturemask=0xffffffff"
  ];

  hardware.firmware = with pkgs; [ linux-firmware ];
  hardware.enableRedistributableFirmware = true;

  boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.linux_cachyos.overrideAttrs (old: {
    makeFlags = old.makeFlags or [] ++ [
      "KCFLAGS=-march=znver5 -mtune=znver5 -O3 -pipe"
    ];
  }));
  
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
