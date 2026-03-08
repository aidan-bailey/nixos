{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    # Forward display-hint env vars to remote hosts
    extraConfig = ''
      SendEnv COLORTERM TERM_PROGRAM
    '';

    matchBlocks = {
      "*" = {
        extraOptions = {
          AddKeysToAgent = "yes";
        };
        identityFile = [
          "~/.ssh/id_ed25519"
          "~/.ssh/id_rsa"
        ];
      };
      fresco = {
        hostname = "fresco.local";
        user = "aidanb";
      };
      nesco = {
        hostname = "nesco.local";
        user = "aidanb";
      };
      medesco = {
        hostname = "medesco.local";
        user = "aidanb";
      };
    };
  };
}
