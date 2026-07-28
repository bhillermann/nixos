{ inputs, ... }:
final: prev: {
  gsd-browser = inputs.self.packages.${prev.system}.gsd-browser;
}
