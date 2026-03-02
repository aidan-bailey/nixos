{
  config,
  lib,
  pkgs,
  ...
}:
{
  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    defaultSopsFile = ../../secrets/home.yaml;
    defaultSopsFormat = "yaml";
  };
}
