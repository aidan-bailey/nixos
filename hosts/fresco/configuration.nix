{
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/devices/fresco.nix
  ];

  custom.hostType = "desktop";
  custom.display.type = "lcd";

  home-manager.users.aidanb.imports = [ ../../home/hosts/fresco.nix ];
}
