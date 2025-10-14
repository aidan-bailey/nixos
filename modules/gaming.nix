{
  config,
  lib,
  pkgs,
  ...
}:

{

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

  environment.systemPackages = with pkgs; [
    steam
  ];

}
