{ inputs, ... }:

final: prev: {
  gsd-core-codex =
    inputs.self.packages.${prev.stdenv.hostPlatform.system}.gsd-core-codex;
}
