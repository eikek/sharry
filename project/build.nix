with import <nixpkgs> { };
let
  initScript = writeScript "sharry-build-init" ''
     export LD_LIBRARY_PATH=
     sbt "$@"
  '';
in
buildFHSUserEnv {
  name = "sharry-sbt";
  targetPkgs = pkgs: with pkgs; [
    netcat jdk8 wget which zsh dpkg sbt git ncurses mc jekyll fakeroot elmPackages.elm
  ];
  runScript = initScript;
}
