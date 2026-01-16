{ inputs, ... }:

final: prev: {
  trade-analysis = inputs.trade-analysis.packages.${prev.system}.default;
}
