cfg: { lib, stdenv, fetchzip, jre8_headless, unzip, bash }:

stdenv.mkDerivation rec {
  name = "sharry-restserver-${cfg.version}";

  src = fetchzip cfg.src;

  buildPhase = "true";

  installPhase = ''
    mkdir -p $out/{bin,sharry-${cfg.version}}
    cp -R * $out/sharry-${cfg.version}/
    cat > $out/bin/sharry-restserver <<-EOF
    #!${bash}/bin/bash
    $out/sharry-${cfg.version}/bin/sharry-restserver -java-home ${jre8_headless} "\$@"
    EOF
    chmod 755 $out/bin/sharry-restserver
  '';

  meta = {
    description = "Sharry allows to share files with others in a simple way.";
    license = lib.licenses.gpl3;
    homepage = https://github.com/eikek/sharry;
  };
}
