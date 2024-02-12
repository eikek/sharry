{ pkgs, lib, sbt }:
let
  meta = (import ./meta.nix) lib;
in
sbt.lib.mkSbtDerivation {
  inherit pkgs;
  inherit (meta) version;
  pname = "sharry";

  src = lib.sourceByRegex ../. [
    "^build.sbt$"
    "^version.sbt$"
    "^artwork"
    "^artwork/.*"
    "^project$"
    "^project/.*$"
    "^modules"
    "^modules/backend"
    "^modules/backend/.*"
    "^modules/common"
    "^modules/common/.*"
    "^modules/logging"
    "^modules/logging/.*"
    "^modules/restapi"
    "^modules/restapi/.*"
    "^modules/restserver"
    "^modules/restserver/.*"
    "^modules/store"
    "^modules/store/.*"
    "^modules/webapp"
    "^modules/webapp/elm.json"
    "^modules/webapp/elm-package.json"
    "^modules/webapp/package.json"
    "^modules/webapp/package-lock.json"
    "^modules/webapp/src"
    "^modules/webapp/src/.*"
    "^modules/webapp/tailwind.config.js"
  ];

  # Elm and npm require a writeable home directory and an internet
  # connection... The trick is to build the webjar in this step and
  # add id to the dependency derivation.
  depsWarmupCommand = ''
    export HOME=$SBT_DEPS/project/home
    mkdir -p $HOME

    # build webapp and add it to the dependencies
    sbt ";update ;make-webapp-only"
    cp modules/webapp/target/scala-*/sharry-webapp_*.jar $HOME/

    # remove garbage
    rm -rf $HOME/.npm $HOME/.elm
  '';

  nativeBuildInputs = with pkgs; [
    cacert
    elmPackages.elm
    tailwindcss
    nodejs_18
  ];

  depsSha256 = "sha256-ulLRZjxGIRVyILicndm8ko4AhOZ1Qbn188J3imifwHg";

  buildPhase = ''
    HOME=$(dirname $COURSIER_CACHE)/home

    mkdir modules/restserver/lib
    cp $HOME/sharry-webapp_*.jar modules/restserver/lib/

    sbt make-without-webapp restserver/Universal/stage
  '';

  installPhase = ''
    mkdir $out
    cp -R modules/restserver/target/universal/stage/* $out/

    cat > $out/bin/sharry <<-EOF
    #!${pkgs.bash}/bin/bash
    $out/bin/sharry-restserver -java-home ${pkgs.jdk17} "\$@"
    EOF
    chmod 755 $out/bin/sharry
  '';

  meta = meta.meta-src;
}
