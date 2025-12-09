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
      libva-vdpau-driver
    ];
  };

  environment.variables = {
    LIBVA_DRIVER_NAME = "radeonsi";
  };


  environment.systemPackages = with pkgs; [
    libva-utils
    lact
    mesa-demos
    radeontop
    vulkan-tools
    glmark2
    libva
  ];

}
