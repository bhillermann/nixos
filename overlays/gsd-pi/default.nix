{ inputs, ... }:

final: prev: {
  gsd-pi = inputs.self.packages.${prev.stdenv.hostPlatform.system}.gsd-pi;
}
