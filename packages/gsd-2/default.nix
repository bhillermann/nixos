{ lib, pkgs, stdenv, ... }:

pkgs.buildNpmPackage rec {
  pname = "gsd-pi";
  version = "2.43.0";

  src = pkgs.fetchFromGitHub {
    owner = "gsd-build";
    repo = "gsd-2";
    rev = "v${version}";
    hash = "sha256-mZKrtbN3CZJslIvAiZhQ2drSigiR90qNpmsZo6l4WII=";
  };

  npmDepsHash = "sha256-4ee6ZhitWCbAAMOBnwXEaKb9Wy4hBeMu2UyfFVPRyF8=";

  meta = with lib; {
    description = "GSD v2 - autonomous coding agent built on the Pi SDK";
    homepage = "https://github.com/gsd-build/gsd-2";
    license = licenses.mit;
    mainProgram = "gsd";
  };
}
