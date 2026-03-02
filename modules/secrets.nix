{
  config,
  lib,
  pkgs,
  ...
}:
let
  secretsTools = with pkgs; [
    sops
    age
    ssh-to-age
  ];
in
{
  environment.systemPackages = secretsTools;
  sops = {
    age.keyFile = "/var/lib/sops-nix/key.txt";
    age.generateKey = true;
    defaultSopsFile = ../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
  };
}
