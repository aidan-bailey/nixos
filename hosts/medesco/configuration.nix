{
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
  ];

  custom.hostType = "server";

  networking.hostName = "medesco";
}
