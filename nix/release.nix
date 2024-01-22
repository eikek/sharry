rec {
  cfg = {
    v1_13_1 = rec {
      version = "1.13.1";
      src = {
        url = "https://github.com/eikek/sharry/releases/download/v${version}/sharry-restserver-${version}.zip";
        sha256 = "sha256-wi4MhgHnKoLMJTZ8pz+ebMbWD7i26/oS+trf3g4nKo0=";
      };
    };
    v1_13_0 = rec {
      version = "1.13.0";
      src = {
        url = "https://github.com/eikek/sharry/releases/download/v${version}/sharry-restserver-${version}.zip";
        sha256 = "sha256-0tfdEd5i1SRSN/kb/gHINiZxOtCWcmzxC4530c7yd3c=";
      };
    };
    v1_12_1 = rec {
      version = "1.12.1";
      src = {
        url = "https://github.com/eikek/sharry/releases/download/v${version}/sharry-restserver-${version}.zip";
        sha256 = "sha256-XiP5s7wJWcTA4zkuDTHWp3+UVvloz3MFrpgboLIz0Ww=";
      };
    };
    v1_11_0 = rec {
      version = "1.11.0";
      src = {
        url = "https://github.com/eikek/sharry/releases/download/v${version}/sharry-restserver-${version}.zip";
        sha256 = "sha256-YzBjeW12V3xxt1EAKg15vHdv5q9DkFQRnE/+WES1alU=";
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
  currentPkg = pkg cfg.v1_13_1;
  module = ./module.nix;
  modules = [ module
            ];
}
