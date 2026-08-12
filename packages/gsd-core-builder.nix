# Shared builder for the GSD-core packages. Deliberately NOT named default.nix:
# snowfall-lib discovers packages by `default.nix` files only, so this file is
# ignored by package auto-discovery and is only ever imported explicitly by the
# gsd-core-claude / gsd-core-codex wrappers.
#
# Runs the GSD installer (`bin/install.js --<runtime> --global`) against a
# per-runtime config dir env var, producing a deterministic GSD install tree.
#
# Output layout:
#   $out/config/         the runtime config dir (CLAUDE_CONFIG_DIR / CODEX_HOME)
#   $out/agents-skills/  the shared agent skills root (~/.agents/skills) — only
#                        present for runtimes that install skills there (Codex).
#                        Claude keeps its skills inside config/skills, so this is
#                        absent for Claude.
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

    export HOME="$TMPDIR/home";              mkdir -p "$HOME"
    export ${configDirEnv}="$out/config";    mkdir -p "$out/config"

    node bin/install.js --${runtime} --global

    # Some runtimes (Codex) install their slash-command skills to the shared
    # agent skills root ~/.agents/skills rather than into the runtime config
    # dir. Capture it so the home module can lay it down at ~/.agents/skills.
    # Claude self-contains its skills under config/skills, so this is a no-op there.
    if [ -d "$HOME/.agents/skills" ]; then
      mkdir -p "$out/agents-skills"
      cp -a "$HOME/.agents/skills/." "$out/agents-skills/"
    fi

    # The installer stamps per-run state (timestamps / install id), which makes
    # the output non-deterministic. We rebuild from scratch every time, so drop it.
    rm -f "$out/config/gsd-install-state.json" "$out/config/gsd-file-manifest.json"

    # Normalise any remaining mtimes the installer may have written as real dates.
    find "$out" -exec touch -h -d @1 {} +
  ''
