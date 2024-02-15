{ modulesPath, config, pkgs, ... }:
{
  imports = [ (modulesPath + "/virtualisation/qemu-vm.nix") ];

  i18n = { defaultLocale = "de_DE.UTF-8"; };
  console.keyMap = "de";

  users.users.root = {
    password = "root";
  };

  virtualisation.memorySize = 2048;
  virtualisation.forwardPorts = [
    {
      from = "host";
      host.port = 64022;
      guest.port = 22;
    }
    {
      from = "host";
      host.port = 64080;
      guest.port = 9090;
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
          oauth = [ ];
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

  networking = {
    hostName = "sharry-test";
    firewall.allowedTCPPorts = [ 9090 ];
  };

  system.stateVersion = "23.11";
}
