{ inputs, ... }:

final: prev: {
  claude-code =
    inputs.claude-code.packages.${prev.stdenv.hostPlatform.system}.default;
}
