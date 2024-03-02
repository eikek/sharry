{
  modulesPath,
  lib,
  config,
  ...
}: {
  imports = [
    (modulesPath + "/virtualisation/qemu-vm.nix")
  ];

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

  users.users.root = {
    password = "root";
    openssh.authorizedKeys.keyFiles = [./dev-vm-key.pub];
  };
  i18n = {defaultLocale = "de_DE.UTF-8";};
  console.keyMap = "de";

  networking = {
    hostName = "sharry-vm";
  };

  virtualisation.memorySize = 2048;

  virtualisation.forwardPorts = [
    {
      from = "host";
      host.port = 10022;
      guest.port = 22;
    }
    {
      from = "host";
      host.port = 19090;
      guest.port = 9090;
    }
    {
      from = "host";
      host.port = 10025;
      guest.port = 25;
    }
    {
      from = "host";
      host.port = 10143;
      guest.port = 143;
    }
    {
      from = "host";
      host.port = 8080;
      guest.port = 80;
    }
    {
      from = "host";
      host.port = 15432;
      guest.port = 5432;
    }
  ];
  documentation.enable = false;
}
