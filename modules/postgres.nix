{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.custom.features.postgresql {
    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_17;

      ensureDatabases = [ "aidanb" ];
      ensureUsers = [
        {
          name = "aidanb";
          ensureDBOwnership = true;
        }
      ];

      authentication = lib.mkOverride 10 ''
        local all all peer
        host all all 127.0.0.1/32 scram-sha-256
        host all all ::1/128 scram-sha-256
      '';

      settings = {
        max_connections = 100;
        shared_buffers = "256MB";
        effective_cache_size = "1GB";
        work_mem = "4MB";
        maintenance_work_mem = "64MB";
      };
    };
  };
}
