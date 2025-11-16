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
  ];

  hardware.firmware = with pkgs; [ linux-firmware ];
  hardware.enableRedistributableFirmware = true;

}
