{ inputs, ... }:

final: prev: {
  trade-analysis = inputs.self.packages.${prev.system}.trade-analysis;
}
