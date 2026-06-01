{ inputs, ... }:

final: prev: {
  gsd-2 = inputs.self.packages.${prev.system}.gsd-2;
}
