{ lib, pkgs, stdenv, ... }:

let
  pname = "gsd-pi";
  version = "3.0.0";

  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/gsd-pi/-/gsd-pi-${version}.tgz";
    hash = "sha256-kiLB8tzZXo54kj0TYfthUP317oh46or5mSUXGH6EByQ=";
  };

  # FOD: real `npm install`, network allowed, result pinned by hash.
  # Captures the whole prepared tree so the workspace symlinks
  # (node_modules/@gsd/* -> ../packages/*) stay internally consistent.
  prepared = stdenv.mkDerivation {
    name = "${pname}-${version}-prepared";
    inherit src;

    nativeBuildInputs = [ pkgs.nodejs_22 pkgs.cacert ];

    dontConfigure = true;
    buildPhase = ''
      runHook preBuild
      export HOME="$TMPDIR"
      npm install --ignore-scripts --omit=dev --no-audit --no-fund
      runHook postBuild
    '';
    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      cp -r . "$out/"
      runHook postInstall
    '';
    dontFixup = true;

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-2d2uIM4Hpy4Bp9rksQg8p3KLC3qXSmuL2Vg337cI3m8=";
  };
in stdenv.mkDerivation {
  inherit pname version;

  dontUnpack = true;
  dontBuild = true;

  nativeBuildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin"
    makeWrapper ${pkgs.nodejs_22}/bin/node "$out/bin/gsd" \
      --add-flags "${prepared}/dist/loader.js"
    runHook postInstall
  '';

  meta = with lib; {
    description = "GSD v2 — autonomous coding agent built on the Pi SDK";
    homepage = "https://github.com/gsd-build/gsd-2";
    license = licenses.mit;
    mainProgram = "gsd";
  };
}
