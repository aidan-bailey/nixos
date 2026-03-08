{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.ssh = {
    enable = true;

    # Forward display-hint env vars to remote hosts
    extraConfig = ''
      SendEnv COLORTERM TERM_PROGRAM
    '';

    matchBlocks = {
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
