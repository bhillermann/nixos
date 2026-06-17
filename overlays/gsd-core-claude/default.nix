{ inputs, ... }:

final: prev: {
  gsd-core-claude =
    inputs.self.packages.${prev.stdenv.hostPlatform.system}.gsd-core-claude;
}
