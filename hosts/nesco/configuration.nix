{
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/devices/zenbook_s16.nix
  ];

  home-manager.users.aidanb.imports = [ ../../home/hosts/nesco.nix ];
}
