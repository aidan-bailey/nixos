{
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
  ];

  custom.hostType = "server";
  custom.display.type = "lcd";

  networking.hostName = "medesco";

  home-manager.users.aidanb.imports = [
    ../../home/hosts/medesco.nix
  ];
}
