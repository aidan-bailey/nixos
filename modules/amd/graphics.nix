{
  config,
  lib,
  pkgs,
  ...
}:

{

  chaotic.mesa-git.enable = true;

  boot.initrd.kernelModules = [ "amdgpu" ];
  services.xserver.videoDrivers = [ "amdgpu" ];

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      mesa
      libvdpau-va-gl
      vaapiVdpau
    ];
  };

  environment.systemPackages = with pkgs; [
    lact
    glxinfo
    radeontop
    mesa-demos
    vulkan-tools
    glmark2
    libva
  ];

}
