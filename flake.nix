{
  description = "Sharry allows to share files with others in a simple way";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
    sbt.url = "github:zaninime/sbt-derivation";
  };

  outputs = inputs@{ self, nixpkgs, flake-utils, sbt }:
    {
      overlays.default = final: prev: {
        sharry = import ./nix/package.nix {
          inherit (final) pkgs;
          inherit sbt;
          lib = final.pkgs.lib;
        };
        sharry-bin = prev.pkgs.callPackage (import ./nix/package-bin.nix) { };
      };
      nixosModules.default = import ./nix/module.nix;

      nixosConfigurations.test-vm =
        let
          system = "x86_64-linux";
          pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [ self.overlays.default ];
          };

        in
        nixpkgs.lib.nixosSystem {
          inherit pkgs system;
          specialArgs = inputs;
          modules = [
            self.nixosModules.default
            ./nix/configuration-test.nix
          ];
        };
    } // flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; overlays = [ self.overlays.default ]; };
      in
      {
        packages = {
          inherit (pkgs) sharry sharry-bin;
          default = self.packages."${system}".sharry;
        };

        formatter = pkgs.nixpkgs-fmt;

        devShells.default =
          let
            run-jekyll = pkgs.writeScriptBin "jekyll-sharry" ''
              jekyll serve -s modules/microsite/target/site --baseurl /sharry
            '';
          in
          pkgs.mkShell {
            buildInputs = with pkgs; [
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
              run-jekyll
            ];
          };
      }
    );
}
