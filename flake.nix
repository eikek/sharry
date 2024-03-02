{
  description = "Sharry allows to share files with others in a simple way";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
    sbt.url = "github:zaninime/sbt-derivation";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-utils,
    sbt,
  }:
    {
      overlays.default = final: prev: {
        sharry = import ./nix/package.nix {
          inherit (final) pkgs;
          inherit sbt;
          lib = final.pkgs.lib;
        };
        sharry-bin = prev.pkgs.callPackage (import ./nix/package-bin.nix) {};
      };
      nixosModules.default = import ./nix/module.nix;

      nixosConfigurations = let
        baseModule = {config, ...}: {system.stateVersion = "23.11";};
      in {
        test-vm = let
          system = "x86_64-linux";
          pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [self.overlays.default];
          };
        in
          nixpkgs.lib.nixosSystem {
            inherit pkgs system;
            specialArgs = inputs;
            modules = [
              baseModule
              self.nixosModules.default
              ./nix/test/configuration-test.nix
            ];
          };

        dev-vm = nixpkgs.lib.nixosSystem {
          system = flake-utils.lib.system.x86_64-linux;
          specialArgs = {inherit inputs;};
          modules = [
            baseModule
            ./nix/devsetup/vm.nix
            ./nix/devsetup/services.nix
          ];
        };

        container = nixpkgs.lib.nixosSystem {
          system = flake-utils.lib.system.x86_64-linux;
          modules = [
            baseModule
            ({pkgs, ...}: {
              boot.isContainer = true;
              networking.useDHCP = false;
            })
            ./nix/devsetup/services.nix
          ];
        };
      };
    }
    // flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [self.overlays.default];
        };
      in {
        packages = {
          inherit (pkgs) sharry sharry-bin;
          default = self.packages."${system}".sharry;
        };

        formatter = pkgs.alejandra;

        devShells = let
          devscripts = (import ./nix/devsetup/dev-scripts.nix) {inherit (pkgs) concatTextFile writeShellScriptBin;};
          allPkgs = devscripts // pkgs;
          commonBuildInputs = with allPkgs; [
            pkgs.sbt

            # frontend
            tailwindcss
            elmPackages.elm

            # for debian packages
            dpkg
            fakeroot

            # microsite
            jekyll
            nodejs_18

            # convenience
            postgresql
          ];
        in {
          default = pkgs.mkShellNoCC {
            SHARRY_CONTAINER = "sharry-dev";
            SHARRY_BACKEND_JDBC_URL = "jdbc:postgresql://sharry-dev:5432/sharry_dev";
            SHARRY_BACKEND_JDBC_USER = "dev";
            SHARRY_BACKEND_JDBC_PASSWORD = "dev";
            SHARRY_BIND_ADDRESS = "0.0.0.0";
            SHARRY_BACKEND_MAIL_SMTP_HOST = "sharry-dev";
            SHARRY_BACKEND_MAIL_SMTP_PORT = "25";
            SHARRY_BACKEND_MAIL_SMTP_USER = "admin";
            SHARRY_BACKEND_MAIL_SMTP_PASSWORD = "admin";
            SHARRY_BACKEND_MAIL_SMTP_SSL__TYPE = "none";

            buildInputs =
              commonBuildInputs
              ++ (with devscripts; [
                # scripts
                devcontainer-recreate
                devcontainer-start
                devcontainer-stop
                devcontainer-login
              ]);
          };

          dev-vm = pkgs.mkShellNoCC {
            SHARRY_BACKEND_JDBC_URL = "jdbc:postgresql://localhost:15432/sharry_dev";
            SHARRY_BACKEND_JDBC_USER = "dev";
            SHARRY_BACKEND_JDBC_PASSWORD = "dev";
            SHARRY_BIND_ADDRESS = "0.0.0.0";
            SHARRY_BACKEND_MAIL_SMTP_HOST = "localhost";
            SHARRY_BACKEND_MAIL_SMTP_PORT = "10025";
            SHARRY_BACKEND_MAIL_SMTP_USER = "admin";
            SHARRY_BACKEND_MAIL_SMTP_PASSWORD = "admin";
            SHARRY_BACKEND_MAIL_SMTP_SSL__TYPE = "none";
            VM_SSH_PORT = "10022";

            buildInputs =
              commonBuildInputs
              ++ (with devscripts; [
                # scripts
                vm-build
                vm-run
                vm-ssh
              ]);
          };
        };
      }
    );
}
