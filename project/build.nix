with import <nixpkgs> { };
mkShell {
  name = "sharry-sbt";
  buildInputs = [
    dpkg sbt git jekyll fakeroot elmPackages.elm
  ];
  shellHook = ''

  '';
}
