{ lib, pkgs, ... }:

let
  version = "1.6.0";

  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@opengsd/gsd-core/-/gsd-core-${version}.tgz";
    hash = "sha256-cB6BHH6s8NxHB/X3ue3wWsF9mlmubKCOlzI9OrYoBlY=";
  };
in
pkgs.runCommand "gsd-core-claude-${version}"
  {
    nativeBuildInputs = [
      pkgs.nodejs_22
      pkgs.gnutar
      pkgs.gzip
    ];

    meta = {
      description = "GSD Core preinstalled for Claude Code (declarative)";
      homepage = "https://github.com/open-gsd/gsd-core";
      license = lib.licenses.mit;
      platforms = lib.platforms.all;
    };
  }
  ''
    mkdir -p pkg
    tar xzf ${src} -C pkg --strip-components=1
    cd pkg

    export HOME="$TMPDIR/home";      mkdir -p "$HOME"
    export CLAUDE_CONFIG_DIR="$out"; mkdir -p "$out"

    node bin/install.js --claude --global

    # The installer stamps per-run state (timestamps / install id), which makes
    # the output non-deterministic. We rebuild from scratch every time, so drop it.
    rm -f "$out/gsd-install-state.json" "$out/gsd-file-manifest.json"

    # Normalise any remaining mtimes the installer may have written as real dates.
    find "$out" -exec touch -h -d @1 {} +
  ''
