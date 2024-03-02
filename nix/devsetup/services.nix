{config, ...}: {
  imports = [
    ./mail.nix
    ./postgres.nix
  ];

  services.devmail = {
    enable = true;
    primaryHostname = "sharry-dev";
  };
}
