lib: rec {
  version = "1.14.0-SNAPSHOT";

  latest-release = "1.13.1";

  license = lib.licenses.gpl3;
  homepage = https://github.com/eikek/sharry;

  meta-bin = {
    description = ''
      Sharry allows to share files with others in a simple way. This
      build is done from published zip files.
    '';

    inherit license homepage;
  };

  meta-src = {
    description = ''
      Sharry allows to share files with others in a simple way. This
      build is done from sources.
    '';

    inherit license homepage;
  };
}
