{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Steam gaming configuration (system-level)
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
    localNetworkGameTransfers.openFirewall = true;
    extraCompatPackages = [
      pkgs.proton-ge-bin
      pkgs.vkd3d-proton
    ];
  };
}

