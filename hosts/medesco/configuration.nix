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
  networking.firewall.allowedTCPPorts = [ 8080 ];

  home-manager.users.aidanb.imports = [
    ../../home/hosts/medesco.nix
  ];
}
