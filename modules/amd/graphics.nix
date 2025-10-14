{
  config,
  lib,
  pkgs,
  ...
}:

{

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      mesa
      libvdpau-va-gl
      vaapiVdpau
    ];
  };

}
