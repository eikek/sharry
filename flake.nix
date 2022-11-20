{
  description = "Sharry allows to share files with others in a simple way";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
  let
    release = import nix/release.nix;
  in
  {
    overlays.default = final: prev: {
      sharryVersions = builtins.mapAttrs (_: cfg: final.callPackage (release.pkg cfg) { }) release.cfg;
      sharry = final.callPackage release.currentPkg { };
    };
    nixosModules.default = release.module;
  } // flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; overlays = [ self.overlays.default ]; };
    in
    {
      packages = {
        inherit (pkgs) sharry;
        default = self.packages."${system}".sharry;
      } // pkgs.sharryVersions;
    }
  );
}
