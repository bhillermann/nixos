{ inputs, ... }:

final: prev: {
  title-search = inputs.title-search.packages.${prev.stdenv.hostPlatform.system}.default;
}
