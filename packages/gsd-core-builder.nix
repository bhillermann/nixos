# Shared builder for the GSD-core packages. Deliberately NOT named default.nix:
# snowfall-lib discovers packages by `default.nix` files only, so this file is
# ignored by package auto-discovery and is only ever imported explicitly by the
# gsd-core-claude / gsd-core-codex wrappers.
#
# Runs the GSD installer (`bin/install.js --<runtime> --global`) against a
# per-runtime config dir env var, producing a deterministic, self-contained
# GSD install tree in $out.
{
  lib,
  pkgs,
  runtime, # "claude" | "codex" | ... (the installer's --<runtime> flag)
  configDirEnv, # "CLAUDE_CONFIG_DIR" | "CODEX_HOME" | ... (points the installer at $out)
}:

let
  version = "1.9.1";

  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@opengsd/gsd-core/-/gsd-core-${version}.tgz";
    hash = "sha256-BR69bZuVQweSLXVCkX/fn9+zrE6H6I3NJK90BeI3N1k=";
  };
in
pkgs.runCommand "gsd-core-${runtime}-${version}"
  {
    nativeBuildInputs = [
      pkgs.nodejs_22
      pkgs.gnutar
      pkgs.gzip
    ];

    meta = {
      description = "GSD Core preinstalled for ${runtime} (declarative)";
      homepage = "https://github.com/open-gsd/gsd-core";
      license = lib.licenses.mit;
      platforms = lib.platforms.all;
    };
  }
  ''
    mkdir -p pkg
    tar xzf ${src} -C pkg --strip-components=1
    cd pkg

    export HOME="$TMPDIR/home";       mkdir -p "$HOME"
    export ${configDirEnv}="$out";    mkdir -p "$out"

    node bin/install.js --${runtime} --global

    # The installer stamps per-run state (timestamps / install id), which makes
    # the output non-deterministic. We rebuild from scratch every time, so drop it.
    rm -f "$out/gsd-install-state.json" "$out/gsd-file-manifest.json"

    # Normalise any remaining mtimes the installer may have written as real dates.
    find "$out" -exec touch -h -d @1 {} +
  ''
