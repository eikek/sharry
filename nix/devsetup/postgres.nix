{
  config,
  pkgs,
  ...
}: {
  networking.firewall.allowedTCPPorts = [config.services.postgresql.port];

  services.postgresql = let
    pginit = pkgs.writeText "pginit.sql" ''
      CREATE USER dev WITH PASSWORD 'dev' LOGIN CREATEDB;
      GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO dev;
      GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO dev;
      CREATE DATABASE sharry_dev OWNER dev;
    '';
  in {
    enable = true;
    package = pkgs.postgresql;
    enableTCPIP = true;
    initialScript = pginit;
    port = 5432;
    settings = {
      listen_addresses = "*";
    };
    authentication = ''
      host  all  all 0.0.0.0/0 trust
    '';
  };
}
