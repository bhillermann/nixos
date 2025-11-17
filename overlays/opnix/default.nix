{ inputs, ...}:


final: prev: {
    opnix = inputs.opnix.packages.${prev.system}.default;
}