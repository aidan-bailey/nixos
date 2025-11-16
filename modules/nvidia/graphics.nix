{
  config,
  lib,
  pkgs,
  ...
}:

{

  chaotic.mesa-git.enable = true;

  #boot.initrd.kernelModules = [ "amdgpu" ];
  #hardware.amdgpu.initrd.enable = lib.mkDefault true;
  
  #services.xserver.videoDrivers = [ "amdgpu" ];

  #hardware.graphics = {
  #  enable = true;
  #  extraPackages = with pkgs; [
  #    mesa
  #    libvdpau-va-gl
  #    vaapiVdpau
  #  ];
  #};

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };


  environment.systemPackages = with pkgs; [
  ];

}
