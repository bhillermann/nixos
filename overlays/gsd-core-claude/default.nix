{ inputs, ... }:

final: prev: {
  gsd-core-claude = inputs.self.packages.${prev.system}.gsd-core-claude;
}
