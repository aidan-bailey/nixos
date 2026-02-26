{
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/base.nix
    ../../modules/user.nix
    ../../modules/networking.nix
    ../../modules/mediaserver.nix
    ../../modules/terminal.nix
  ];

  networking.hostName = "medesco"; # Define your hostname.
}
