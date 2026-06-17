{ inputs, ...}:

final: prev: {
    geodiff = inputs.self.packages.${prev.stdenv.hostPlatform.system}.geodiff;
}