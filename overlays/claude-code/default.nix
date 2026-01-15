{ inputs, ... }:

final: prev: {
  claude-code = inputs.claude-code.packages.${prev.system}.default;
}
