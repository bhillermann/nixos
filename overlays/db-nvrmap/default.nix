{ inputs, ... }:

final: prev: {
  db-nvrmap =
    inputs.db-nvrmap.packages.${prev.stdenv.hostPlatform.system}.default;
}
