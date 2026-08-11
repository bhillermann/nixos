{ lib, pkgs, ... }:

import ../gsd-core-builder.nix {
  inherit lib pkgs;
  runtime = "codex";
  configDirEnv = "CODEX_HOME";
}
