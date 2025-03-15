{
  description = "Sharry allows to share files with others in a simple way";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
    sbt.url = "github:zaninime/sbt-derivation";
    devshell-tools.url = "github:eikek/devshell-tools";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-utils,
    devshell-tools,
    sbt,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      sbt17 = pkgs.sbt.override {jre = pkgs.jdk17;};
      ciPkgs = with pkgs; [
        sbt17
        jdk17
        dpkg
        elmPackages.elm
        fakeroot
        nodejs
        redocly-cli
        tailwindcss
        jekyll
      ];
      devshellPkgs =
        ciPkgs
        ++ (with pkgs; [
          jq
          scala-cli
          netcat
          wget
          which
          postgresql
          inotifyTools
        ]);
      sharryPkgs = {
        sharry-dev = import ./nix/package-dev.nix {
          inherit pkgs;
          inherit sbt;
          lib = pkgs.lib;
        };
        sharry = pkgs.callPackage (import ./nix/package-bin.nix) {};
      };
    in {
      formatter = pkgs.alejandra;

      packages = {
        inherit (sharryPkgs) sharry sharry-dev;
        default = sharryPkgs.sharry;
      };

      devShells = {
        dev-cnt = pkgs.mkShellNoCC {
          buildInputs =
            (builtins.attrValues devshell-tools.legacyPackages.${system}.cnt-scripts)
            ++ devshellPkgs;

          DEV_CONTAINER = "sharry-dev";
          SBT_OPTS = "-Xmx1g";
          SHARRY_BACKEND_JDBC_URL = "jdbc:postgresql://sharry-dev:5432/sharry";
          SHARRY_BACKEND_JDBC_USER = "dev";
          SHARRY_BACKEND_JDBC_PASSWORD = "dev";
          SHARRY_BIND_ADDRESS = "0.0.0.0";
          SHARRY_BACKEND_MAIL_SMTP_HOST = "sharry-dev";
          SHARRY_BACKEND_MAIL_SMTP_PORT = "25";
          SHARRY_BACKEND_MAIL_SMTP_USER = "admin";
          SHARRY_BACKEND_MAIL_SMTP_PASSWORD = "admin";
          SHARRY_BACKEND_MAIL_SMTP_SSL_TYPE = "none";
        };

        dev-vm = pkgs.mkShellNoCC {
          buildInputs =
            (builtins.attrValues devshell-tools.legacyPackages.${system}.vm-scripts)
            ++ devshellPkgs;

          SBT_OPTS = "-Xmx1g";
          DEV_VM = "dev-vm";
          VM_SSH_PORT = "10022";
          SHARRY_BACKEND_JDBC_URL = "jdbc:postgresql://localhost:6534/sharry";
          SHARRY_BACKEND_JDBC_USER = "dev";
          SHARRY_BACKEND_JDBC_PASSWORD = "dev";
          SHARRY_BIND_ADDRESS = "0.0.0.0";
          SHARRY_BACKEND_MAIL_SMTP_HOST = "localhost";
          SHARRY_BACKEND_MAIL_SMTP_PORT = "10025";
          SHARRY_BACKEND_MAIL_SMTP_USER = "admin";
          SHARRY_BACKEND_MAIL_SMTP_PASSWORD = "admin";
          SHARRY_BACKEND_MAIL_SMTP_SSL_TYPE = "none";
        };
        ci = pkgs.mkShellNoCC {
          buildInputs = ciPkgs;
          SBT_OPTS = "-Xmx2G -Xss4m";
        };
      };
    })
    // {
      nixosModules.default = import ./nix/module.nix;

      overlays.default = final: prev: let
        sharryPkgs = {
          sharry-dev = import ./nix/package-dev.nix {
            inherit (final) pkgs;
            inherit sbt;
            lib = final.pkgs.lib;
          };
          sharry = prev.pkgs.callPackage (import ./nix/package-bin.nix) {};
        };
      in {
        inherit (sharryPkgs) sharry sharry-dev;
      };

      nixosConfigurations = {
        test-vm = devshell-tools.lib.mkVm {
          system = "x86_64-linux";
          modules = [
            self.nixosModules.default
            {
              nixpkgs.overlays = [self.overlays.default];
            }
            ./nix/test/configuration-test.nix
          ];
        };
        sharry-dev = devshell-tools.lib.mkContainer {
          system = "x86_64-linux";
          modules = [
            {
              services.dev-postgres = {
                enable = true;
                databases = ["sharry"];
              };
              services.dev-email.enable = true;
              services.dev-minio.enable = true;
            }
          ];
        };
        dev-vm = devshell-tools.lib.mkVm {
          system = "x86_64-linux";
          modules = [
            {
              networking.hostName = "sharry-dev-vm";
              virtualisation.memorySize = 2048;

              services.dev-postgres = {
                enable = true;
                databases = ["sharry"];
              };
              services.dev-email.enable = true;
              services.dev-minio.enable = true;
              port-forward.ssh = 10022;
              port-forward.dev-postgres = 6534;
              port-forward.dev-smtp = 10025;
              port-forward.dev-imap = 10143;
              port-forward.dev-webmail = 8080;
              port-forward.dev-minio-api = 9000;
              port-forward.dev-minio-console = 9001;
            }
          ];
        };
      };
    };
}
