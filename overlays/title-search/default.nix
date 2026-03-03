{ inputs, ... }:

final: prev: {
  title-search = inputs.title-search.packages.${prev.system}.default;
}
