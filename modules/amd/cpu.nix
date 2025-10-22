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

  boot.kernelPackages = pkgs.linuxPackages_cachyos;

}
