{ lib, inputs, pkgs, ... }:

let
  src = pkgs.fetchFromGitHub {
    owner = "open-gsd";
    repo = "gsd-core";
    rev = "v1.4.3";
    hash = lib.fakeHash; # replace with the real hash after the first build
  };
in pkgs.runCommand "gsd-core-claude-1.4.3" {
  nativeBuildInputs = [ pkgs.nodejs_22 ];

  meta = {
    description = "GSD Core preinstalled for Claude Code (declarative)";
    homepage = "https://github.com/open-gsd/gsd-core";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
} ''
  cp -r ${src} ./pkg
  chmod -R +w ./pkg
  cd ./pkg

  export HOME="$TMPDIR/home";      mkdir -p "$HOME"
  export CLAUDE_CONFIG_DIR="$out"; mkdir -p "$out"

  # Sandbox enforces no-network + no-writes-outside-$out. If this throws
  # MODULE_NOT_FOUND, install.js needs its runtime deps — see note below.
  node bin/install.js --claude --global
''
