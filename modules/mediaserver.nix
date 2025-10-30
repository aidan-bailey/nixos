{
  config,
  lib,
  pkgs,
  nixpkgs,
  ...
}:

{

  environment.systemPackages = [ 
	pkgs.transmission_4-qt
	pkgs.jellyfin-media-player
  ];

  nixarr = {
    enable = true;
    mediaDir = "/data/media";
    stateDir = "/data/media/.state/nixarr";

    vpn = {
      enable = false;
    };

    jellyfin = {
      enable = true;
    };

    transmission = {
      enable = true;
      #vpn.enable = true;
      #peerPort = 50000;
    };

    bazarr.enable = true;
    lidarr.enable = true;
    prowlarr.enable = true;
    radarr.enable = true;
    readarr.enable = true;
    sonarr.enable = true;
    jellyseerr.enable = true;


  };

  nixpkgs.config.permittedInsecurePackages = [
    "qtwebengine-5.15.19"
  ];

  services.flaresolverr = {
  enable = true;
  openFirewall = false;   # true only if you want to access externally
  port = 8191;
  };

}
