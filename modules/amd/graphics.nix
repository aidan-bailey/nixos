{
  config,
  lib,
  pkgs,
  ...
}:

{

  chaotic.mesa-git.enable = true;

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
    glmark2
    libva
  ];

}
