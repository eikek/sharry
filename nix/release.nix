rec {
  cfg = {
    v1_4_0 = rec {
      version = "1.4.0";
      src = {
        url = "https://github.com/eikek/sharry/releases/download/release%2F${version}/sharry-restserver-${version}.zip";
        sha256 = "0msgnnalg68zjyasli4xn85bm15dj7a77k0ggn3j6yc9kpfkfd75";
      };
    };
    v1_3_1 = rec {
      version = "1.3.1";
      src = {
        url = "https://github.com/eikek/sharry/releases/download/release%2F${version}/sharry-restserver-${version}.zip";
        sha256 = "1nz2w9bjgsb9zl18sajcsgklf42x2z00zvljkb38h9bwvf6dr5wj";
      };
    };
    v1_3_0 = rec {
      version = "1.3.0";
      src = {
        url = "https://github.com/eikek/sharry/releases/download/release%2F${version}/sharry-restserver-${version}.zip";
        sha256 = "1pqyg23yz7x8v42w674ryrhlsl6wlvf92gyv3v311wzlsh1prajv";
      };
    };
    v1_2_0 = rec {
      version = "1.2.0";
      src = {
        url = "https://github.com/eikek/sharry/releases/download/release%2F${version}/sharry-restserver-${version}.zip";
        sha256 = "136jd2ifd6knnhn2pzjia47ihykvxa0w6pvignf6qypbyavr5y47";
      };
    };
    v1_1_0 = rec {
      version = "1.1.0";
      src = {
        url = "https://github.com/eikek/sharry/releases/download/release%2F${version}/sharry-restserver-${version}.zip";
        sha256 = "0c50v444npfrdlsw3qp4cni4pi4pfyzaijhh9bfm2xn5pz7ib9sm";
      };
    };
    v1_0_0 = rec {
      version = "1.0.0";
      src = {
        url = "https://github.com/eikek/sharry/releases/download/release%2F${version}/sharry-restserver-${version}.zip";
        sha256 = "1s0s8ifm2migwz2lzcy06ra4a4pv8aphggv7mmkqik98fij2kr7q";
      };
    };
  };
  pkg = v: import ./pkg.nix v;
  currentPkg = pkg cfg.v1_4_0;
  module = ./module.nix;
  modules = [ module
            ];
}
