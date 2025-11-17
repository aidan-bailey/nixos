{ config, pkgs, ... }:

{
  # Steam gaming configuration
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

  # Gaming applications
  home.packages = with pkgs; [
    steam
    cockatrice
  ];
}

