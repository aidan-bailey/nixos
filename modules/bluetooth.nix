{
  config,
  lib,
  pkgs,
  ...
}:

{

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;
        Enable = "Source,Sink,Media,Socket";
      };
    };
  };

  services.upower.enable = true;

  services.blueman.enable = true;

  environment.systemPackages = with pkgs; [
    blueman
  ];

}
