{ inputs, ... }:

# nixos-26.05 ships 1.5.8; unstable tracks upstream (1.6.4 as of Oct 2026) and is cached.
final: prev: {
  rapidraw = inputs.nixpkgs-unstable.legacyPackages.${prev.stdenv.hostPlatform.system}.rapidraw;
}
