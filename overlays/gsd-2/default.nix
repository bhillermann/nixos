{ inputs, ... }:

final: prev: {
  gsd-2 = inputs.self.packages.${prev.stdenv.hostPlatform.system}.gsd-2;
}
