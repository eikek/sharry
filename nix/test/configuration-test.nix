{
  modulesPath,
  config,
  pkgs,
  ...
}: {
  services.dev-postgres = {
    enable = true;
    databases = ["sharry"];
  };
  services.dev-email.enable = true;

  port-forward.dev-webmail = 8080;
  port-forward.dev-solr = 8983;

  environment.systemPackages = with pkgs; [
    jq
    htop
    iotop
    coreutils
  ];

  networking = {
    hostName = "sharry-test-vm";
    firewall.allowedTCPPorts = [9090];
  };

  virtualisation.memorySize = 2048;
  virtualisation.forwardPorts = [
    {
      from = "host";
      host.port = 9090;
      guest.port = 9091;
    }
  ];

  services.sharry = {
    enable = true;
    config = {
      bind.address = "0.0.0.0";
      base-url = "http://localhost:9090";
      webapp = {
        default-language = "de";
      };
      backend = {
        auth = {
          oauth = [];
        };
        share = {
          database-domain-checks = [
            {
              enabled = true;
              native = "domain safe_bytea violates check constraint";
              message = "The uploaded file contains a virus!";
            }
          ];
        };
      };
    };
  };

  services.xserver = {
    enable = false;
  };
}
