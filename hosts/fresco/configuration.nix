{
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/devices/fresco.nix
  ];

  home-manager.users.aidanb.imports = [ ../../home/hosts/fresco.nix ];
}
