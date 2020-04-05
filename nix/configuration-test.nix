{ config, pkgs, ... }:
let
  sharry = import ./release.nix;
in
{
  imports = sharry.modules;

  i18n = {
    consoleKeyMap = "neo";
    defaultLocale = "en_US.UTF-8";
  };

  users.users.root = {
    password = "root";
  };

  nixpkgs = {
    config = {
      packageOverrides = pkgs:
        let
          callPackage = pkgs.lib.callPackageWith(custom // pkgs);
          custom = {
            sharry = callPackage sharry.currentPkg {};
          };
        in custom;
    };
  };

  services.sharry = {
    enable = true;
    bind.address = "0.0.0.0";
    base-url = "http://localhost:9090";
    backend = {
      auth = {
        oauth = [];
      };
    };
  };

  services.xserver = {
    enable = false;
  };

  networking = {
    hostName = "sharrytest";
    firewall.allowedTCPPorts = [ 9090 ];
  };

  system.stateVersion = "19.09";

}
