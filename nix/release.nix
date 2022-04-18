rec {
  cfg = {
    v1_10_0 = rec {
      version = "1.10.0";
      src = {
        url = "https://github.com/eikek/sharry/releases/download/v${version}/sharry-restserver-${version}.zip";
        sha256 = "sha256-CbuBnuSfUsOgsAWqzSRXLhB/fd76AOuD7B7f9MuT8nk=";
      };
    };
    v1_9_0 = rec {
      version = "1.9.0";
      src = {
        url = "https://github.com/eikek/sharry/releases/download/v${version}/sharry-restserver-${version}.zip";
        sha256 = "0wx41sw7272g26jx3c93ixl0ky1jswdhlcvkxmzf1gyg9vs26nyc";
      };
    };
    v1_8_0 = rec {
      version = "1.8.0";
      src = {
        url = "https://github.com/eikek/sharry/releases/download/v${version}/sharry-restserver-${version}.zip";
        sha256 = "034qlf4y2j6gjyy3fkpfrcz3d1nrvyp2n75ssh4ani64qqld028k";
      };
    };
    v1_7_1 = rec {
      version = "1.7.1";
      src = {
        url = "https://github.com/eikek/sharry/releases/download/v${version}/sharry-restserver-${version}.zip";
        sha256 = "011zj8iq0zmb22zn49b5dlqqm707bvrqnv9xvxn2z96d6cgi47an";
      };
    };
    v1_6_0 = rec {
      version = "1.6.0";
      src = {
        url = "https://github.com/eikek/sharry/releases/download/release%2F${version}/sharry-restserver-${version}.zip";
        sha256 = "0fd77hv1sqwfybxgcvxkwgw9qlm7iqhvaasgkj7cq7ka9nbcrbcy";
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
  currentPkg = pkg cfg.v1_10_0;
  module = ./module.nix;
  modules = [ module
            ];
}
