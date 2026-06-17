{ inputs, ... }:

final: prev: {
  trade-analysis =
    inputs.trade-analysis.packages.${prev.stdenv.hostPlatform.system}.default;
}
