{
  config,
  lib,
  pkgs,
  ...
}:
let
  tunnelId = "915ba136-c8a8-43f9-9359-167f9d55a73f";
  unit = "cloudflared-tunnel-${tunnelId}.service";
in
{
  environment.systemPackages = [ pkgs.cloudflared ];

  users.users.cloudflared = {
    isSystemUser = true;
    group = "cloudflared";
    description = "Cloudflare Tunnel daemon";
  };
  users.groups.cloudflared = { };

  sops.secrets."cloudflared/medesco.json" = {
    sopsFile = ../secrets/medesco.yaml;
    key = "cloudflared_credentials";
    owner = "cloudflared";
    group = "cloudflared";
    mode = "0400";
    restartUnits = [ unit ];
  };

  services.cloudflared = {
    enable = true;
    tunnels.${tunnelId} = {
      credentialsFile = config.sops.secrets."cloudflared/medesco.json".path;
      default = "http_status:404";
      ingress = {
        "jellyfin.aidanbailey.me" = "http://localhost:8096";
        "jellyseerr.aidanbailey.me" = "http://localhost:5055";
        "sonarr.aidanbailey.me" = "http://localhost:8989";
        "radarr.aidanbailey.me" = "http://localhost:7878";
        "bazarr.aidanbailey.me" = "http://localhost:6767";
        "prowlarr.aidanbailey.me" = "http://localhost:9696";
        "lidarr.aidanbailey.me" = "http://localhost:8686";
        "transmission.aidanbailey.me" = "http://localhost:9091";
        "fresco.aidanbailey.me" = "ssh://192.168.88.246:22";
        "medesco.aidanbailey.me" = "ssh://localhost:22";
      };
    };
  };

  systemd.services.${unit}.serviceConfig = {
    DynamicUser = lib.mkForce false;
    User = "cloudflared";
    Group = "cloudflared";
  };
}
