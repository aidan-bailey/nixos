{
  config,
  lib,
  pkgs,
  ...
}:

{

  boot.initrd.kernelModules = [ "amdgpu" ];
  hardware.amdgpu.initrd.enable = lib.mkDefault true;
  
  services.xserver.videoDrivers = [ "amdgpu" ];

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      mesa
      libvdpau-va-gl
      vaapiVdpau
    ];
  };

  environment.variables = {
    LIBVA_DRIVER_NAME = "radeonsi";
  };


  environment.systemPackages = with pkgs; [
    libva-utils
    lact
    glxinfo
    radeontop
    mesa-demos
    vulkan-tools
    glmark2
    libva
  ];

}
