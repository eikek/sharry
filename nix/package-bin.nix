{ lib, stdenv, fetchzip, jdk17, unzip, bash }:
let
  meta = (import ./meta.nix) lib;
  version = meta.latest-release;
in
stdenv.mkDerivation {
  inherit version;
  name = "sharry-bin-${version}";

  src = fetchzip {
    url = "https://github.com/eikek/sharry/releases/download/v${version}/sharry-restserver-${version}.zip";
    sha256 = "sha256-wi4MhgHnKoLMJTZ8pz+ebMbWD7i26/oS+trf3g4nKo0=";
  };

  buildPhase = "true";

  installPhase = ''
    mkdir -p $out/{bin,sharry-${version}}
    cp -R * $out/sharry-${version}/
    cat > $out/bin/sharry <<-EOF
    #!${bash}/bin/bash
    $out/sharry-${version}/bin/sharry-restserver -java-home ${jdk17} "\$@"
    EOF
    chmod 755 $out/bin/sharry
  '';

  meta = meta.meta-bin;
}
