{ lib, pkgs, ... }:

let
  version = "1.4.3";

  src = pkgs.fetchurl {
    url =
      "https://registry.npmjs.org/@opengsd/gsd-core/-/gsd-core-${version}.tgz";
    hash = "sha256-0gW+YyP53Q9Q7DJA9fcerBS+2Tz2o04hj1gjWVjpdJg=";
  };
in pkgs.runCommand "gsd-core-claude-${version}" {
  nativeBuildInputs = [ pkgs.nodejs_22 pkgs.gnutar pkgs.gzip ];

  meta = {
    description = "GSD Core preinstalled for Claude Code (declarative)";
    homepage = "https://github.com/open-gsd/gsd-core";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
} ''
  mkdir -p pkg
  tar xzf ${src} -C pkg --strip-components=1   # npm tarballs nest under package/
  cd pkg

  export HOME="$TMPDIR/home";      mkdir -p "$HOME"
  export CLAUDE_CONFIG_DIR="$out"; mkdir -p "$out"

  node bin/install.js --claude --global
''
