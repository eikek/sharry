rec {
  cfg = {
    v1_0_0 = rec {
      version = "1.0.0";
      src = {
        url = "https://github.com/eikek/sharry/releases/download/release%2F${version}/sharry-restserver-${version}.zip";
        sha256 = "1s0s8ifm2migwz2lzcy06ra4a4pv8aphggv7mmkqik98fij2kr7q";
      };
    };
  };
  pkg = v: import ./pkg.nix v;
  currentPkg = pkg cfg.v1_0_0;
  module = ./module.nix;
  modules = [ module
            ];
}
