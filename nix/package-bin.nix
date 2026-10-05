{
  lib,
  stdenv,
  fetchzip,
  jdk,
  unzip,
  bash,
}: let
  meta = (import ./meta.nix) lib;
  version = meta.latest-release;
in
  stdenv.mkDerivation {
    inherit version;
    name = "sharry-bin-${version}";

    src = fetchzip {
      url = "https://github.com/eikek/sharry/releases/download/v${version}/sharry-restserver-${version}.zip";
      sha256 = "sha256-JK6Cu8K3yMlfCHtneLM8SMeixZMsXikbU6HsMg+LUi8=";
    };

    buildPhase = "true";

    installPhase = ''
      mkdir -p $out/{bin,sharry-${version}}
      cp -R * $out/sharry-${version}/
      cat > $out/bin/sharry <<-EOF
      #!${bash}/bin/bash
      $out/sharry-${version}/bin/sharry-restserver -java-home ${jdk} "\$@"
      EOF
      chmod 755 $out/bin/sharry
    '';

    meta = meta.meta-bin;
  }
