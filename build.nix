with import <nixpkgs> { };
let
  nixpkgs1803dist = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/18.03.tar.gz";
    sha256 = "0hk4y2vkgm1qadpsm4b0q1vxq889jhxzjx3ragybrlwwg54mzp4f";
  };
  pkgs1803 = import nixpkgs1803dist {};
  initScript = writeScript "sharry-build-init" ''
     export LD_LIBRARY_PATH=
     ${bash}/bin/bash -c sbt
  '';
in
buildFHSUserEnv {
  name = "sharry-sbt";
  targetPkgs = pkgs: with pkgs; [
    netcat jdk8 wget which zsh dpkg sbt git pkgs1803.elmPackages.elm ncurses fakeroot mc jekyll
    # haskells http client needs this (to download elm packages)
    iana-etc
  ];
  runScript = ''
    ${initScript}
  '';
}
