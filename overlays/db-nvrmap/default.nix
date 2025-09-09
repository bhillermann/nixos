{ inputs, ...}:


final: prev: {
    db-nvrmap = inputs.db-nvrmap.packages.${prev.system}.default;
}
