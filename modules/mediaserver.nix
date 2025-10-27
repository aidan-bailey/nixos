{
  config,
  lib,
  pkgs,
  ...
}:

{
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
      enable = false;
      vpn.enable = true;
      peerPort = 50000;
    };

    bazarr.enable = true;
    lidarr.enable = true;
    prowlarr.enable = true;
    radarr.enable = true;
    readarr.enable = true;
    sonarr.enable = true;
    jellyseerr.enable = true;
  };
}
