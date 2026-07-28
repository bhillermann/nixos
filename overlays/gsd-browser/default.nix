{ inputs, ... }:
final: prev: {
  gsd-browser = inputs.self.packages.${prev.stdenv.hostPlatform.system}.gsd-browser;
}
