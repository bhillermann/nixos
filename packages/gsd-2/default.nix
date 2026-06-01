{ lib, pkgs, stdenv, ... }:

let
  packageLock = pkgs.writeText "gsd-pi-package-lock.json"
    (builtins.readFile ./package-lock.json);

in pkgs.buildNpmPackage rec {
  pname = "gsd-pi";
  version = "3.0.0";

  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/gsd-pi/-/gsd-pi-${version}.tgz";
    hash = "sha256:0907hiz1h5r5k7wqmskqi3pgbzahc7xn24rxj9w8wpnrvkrc28lj";
  };

  npmDepsHash = "sha256-fd9Gbdbqo38in3lXmnN87cuvv2Jp0fksXzsfQf0Jv5I=";

  prePatch = ''
    cp ${packageLock} package-lock.json
  '';

  dontNpmBuild = true;

  npmInstallFlags = [ "--ignore-scripts" ];

  meta = with lib; {
    description = "GSD v2 - autonomous coding agent built on the Pi SDK";
    homepage = "https://github.com/gsd-build/gsd-2";
    license = licenses.mit;
    mainProgram = "gsd";
  };
}
