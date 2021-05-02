let
  nixpkgs = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/refs/tags/20.09.tar.gz";
  };
  pkgs = import nixpkgs { };
  run-jekyll = pkgs.writeScript "run-jekyll" ''
    jekyll serve -s modules/microsite/target/site --baseurl /sharry
  '';
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    jekyll sbt git
  ];
  shellHook = ''
    alias jekyll-sharry=${run-jekyll}
  '';
}
