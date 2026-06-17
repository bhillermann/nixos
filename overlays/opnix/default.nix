{ inputs, ... }:

final: prev: {
  opnix = inputs.opnix.packages.${prev.stdenv.hostPlatform.system}.default;
}
