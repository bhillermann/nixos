{ inputs, ...}:

final: prev: {
    geodiff = inputs.self.packages.${prev.system}.geodiff;
}